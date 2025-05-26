# ===================================================================================== #
#                 🛠️ JENKINS + SONARQUBE SAST PIPELINE — TROUBLESHOOTING               #
# ===================================================================================== #

  This guide helps you understand the common issues faced while setting up a 
  secure pipeline using Jenkins + SonarQube via Docker Compose — and how to 
  avoid or fix them efficiently.

# ------------------------------------------------------------------------------------- #
# 1️⃣  JENKINS SKIPS SETUP WIZARD
# ------------------------------------------------------------------------------------- #
🔍  Reason:
    - Existing Jenkins volume already has config (config.xml)
    - Or: JAVA_OPTS disables the setup wizard

💡  Fix:
    $ docker-compose down -v      # Remove persistent volumes
    ✅ Don’t set:
    JAVA_OPTS=-Djenkins.install.runSetupWizard=false

# ------------------------------------------------------------------------------------- #
# 2️⃣  JENKINS + SONARQUBE CONFLICT (LOW MEMORY)
# ------------------------------------------------------------------------------------- #
🔍  Reason:
    - EC2 or local system has <2 GB RAM
    - SonarQube (Elasticsearch) and Jenkins both are memory heavy

💡  Fix:
    - Use t3.medium (4GB) or higher instance
    - Or run one at a time:
      $ docker-compose stop sonarqube

#--------------------------------------------------------------------------------------#

I used SWAP mem to fix this instead of upgrading to t3. medium

💡 Swap memory helps prevent crashes when physical RAM is exhausted.
Useful when running Jenkins + SonarQube on low-RAM EC2 instances.

---

# ✅ 1. Check If Swap Is Enabled

$ free -h

# Output:
#              total        used        free      shared  buff/cache   available
# Mem:          987Mi        ...
# Swap:            0B          0B         0B

🔍 If swap is 0B → proceed to enable it.

---

# ✅ 2. Create a 4GB Swap File

$ sudo fallocate -l 4G /swapfile

# If fallocate not available, use:
$ sudo dd if=/dev/zero of=/swapfile bs=1M count=4096

---

# ✅ 3. Set Permissions

$ sudo chmod 600 /swapfile

---

# ✅ 4. Format and Enable Swap

$ sudo mkswap /swapfile
$ sudo swapon /swapfile

---

# ✅ 5. Make It Persistent Across Reboots

$ echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

---

# ✅ 6. Verify Swap Is Active

$ free -h

# Output:
#              total        used        free      shared  buff/cache   available
# Swap:          4.0G        0B         4.0G

🎉 Success! Swap memory is now enabled.

---

# ------------------------------------------------------------------------------------- #
# 3️⃣  JENKINS UI BROKEN / UNRESPONSIVE
# ------------------------------------------------------------------------------------- #
🔍  Reason:
    - CSS/JS assets not loaded properly due to low memory

💡  Fix:
    - Hard refresh browser → Ctrl + Shift + R
    - Try incognito mode
    - Check logs:
      $ docker logs jenkins

# ------------------------------------------------------------------------------------- #
# 4️⃣  SONARQUBE STUCK ON “STARTING…”
# ------------------------------------------------------------------------------------- #
🔍  Reason:
    - vm.max_map_count not set (required by Elasticsearch)
    - Insufficient memory or Docker storage driver issues

💡  Fix:
    $ sysctl -w vm.max_map_count=262144

# ------------------------------------------------------------------------------------- #
# 5️⃣  JENKINS: “COULDN’T FIND ANY REVISION TO BUILD”
# ------------------------------------------------------------------------------------- #
🔍  Reason:
    - Branch mismatch (`master` vs `main`)
    - Git not installed inside Jenkins container

💡  Fix:
    - Update branch name to `main`(if its main- mine was main)
    - Install Git:
      $ docker exec -it jenkins bash
      $ apt update && apt install git -y

    - Test:
      $ docker exec -it jenkins git ls-remote https://github.com/your/repo.git

# ------------------------------------------------------------------------------------- #
# 6️⃣  `sonar-scanner: not found` ERROR
# ------------------------------------------------------------------------------------- #
🔍  Reason:
    - Jenkins pipeline can't find `sonar-scanner` in PATH

💡  Fix:
    - Use `tool` inside `script` block in Jenkinsfile:

      withSonarQubeEnv('SonarQube') {
        script {
          def scannerHome = tool name: 'SonarScanner', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
          sh "${scannerHome}/bin/sonar-scanner"
        }
      }

# ------------------------------------------------------------------------------------- #
# 7️⃣  `waitForQualityGate` TIMEOUT
# ------------------------------------------------------------------------------------- #
🔍  Reason:
    - SonarQube didn’t notify Jenkins that analysis is complete
    - Webhook not configured or Jenkins not reachable

💡  Fix:
    → Add webhook in SonarQube:
      Go to: Administration → Configuration → Webhooks

      Name: Jenkins
      URL : http://<jenkins-host>:8080/sonarqube-webhook/

    → Update Jenkinsfile timeout (default is too short):
      timeout(time: 5, unit: 'MINUTES') {
        waitForQualityGate abortPipeline: true
      }

    → Check if webhook hits Jenkins:
      $ docker logs jenkins | grep sonarqube-webhook

# ------------------------------------------------------------------------------------- #
# ✅ RECOMMENDED CHECKLIST
# ------------------------------------------------------------------------------------- #
☑️  docker-compose up -d         → Services start
☑️  Jenkins plugins installed    → Git, SonarQube Scanner
☑️  Git works inside Jenkins     → git ls-remote succeeds
☑️  Scanner configured           → Global Tool Config
☑️  Jenkinsfile uses script/tool correctly
☑️  Webhook configured in SonarQube

# ===================================================================================== #
#                 💡 TIP: Keep this file updated as part of `docs/` folder              #
# ===================================================================================== #
