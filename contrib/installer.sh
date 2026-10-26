#!/bin/bash
#
# Clone the repository in the `work` qube and copy only this single file into dom0 to then run it, e.g.:
#
# ```
# qvm-run --pass-io work 'cat /home/user/qubes-buskill/contrib/installer.sh' > installer.sh
# bash installer.sh
# ```

set -euo pipefail

if [ ! command -v qubes-dom0-update ]; then
  echo "This installer must be run in dom0, not in the qube, where you cloned this repo."
  exit 1
fi

SRC_QUBE="work"
CONTRIB_DIR="/home/user/qubes-buskill/contrib"

GPG_KEY_FILE="RPM-GPG-KEY-qubes-buskill"
FEDORA_TEMPLATEVM_REPO_FILE="qubes-buskill-vm.repo"
DEBIAN_TEMPLATEVM_REPO_FILE="qubes-buskill.list"
DOM0_REPO_FILE="qubes-buskill-dom0.repo"

copy_file_from_src_qube() {
  local FILENAME="$1"
  echo "Fetching ${FILENAME} from ${SRC_QUBE}:${CONTRIB_DIR}/"
  qvm-run --pass-io "$SRC_QUBE" "cat '${CONTRIB_DIR}/${FILENAME}'" > "${WORKDIR}/${FILENAME}"
  [ -s "${WORKDIR}/${FILENAME}" ] || echo "Fetched ${FILENAME} is empty - is ${CONTRIB_DIR} correct in the qube '${SRC_QUBE}'?"
}

install_file_as_root() {
  local TARGET_QUBE="$1" FILE_IN_DOM0="$2" FILE_DESTINATION="$3"
  qvm-run --pass-io -u root "$TARGET_QUBE" "cat > '${FILE_DESTINATION}'" < "${WORKDIR}/${FILE_IN_DOM0}"
}

echo "Detecting supported TemplateVMs"

FEDORA_TEMPLATEVMS=()
DEBIAN_TEMPLATEVMS=()
mapfile -t ALL_TEMPLATEVMS < <(qvm-ls --raw-data --fields NAME,CLASS | grep TemplateVM | cut -d '|' -f 1)

for TEMPLATEVM in "${ALL_TEMPLATEVMS[@]}"; do
  case "$TEMPLATEVM" in
    fedora-[0-9]*) FEDORA_TEMPLATEVMS+=("$TEMPLATEVM") ;;
    debian-[0-9]*) DEBIAN_TEMPLATEVMS+=("$TEMPLATEVM") ;;
  esac
done

if [ ${#FEDORA_TEMPLATEVMS[@]} -eq 0 ] && [ ${#DEBIAN_TEMPLATEVMS[@]} -eq 0 ]; then
  echo "BusKill requires a Debian/Fedora TemplateVM installed. Install at least one of these and ensure that your USB qube is based on it."
  exit 1
fi

cat <<EOF
About to install BusKill:
  - from source qube: ${SRC_QUBE},
  - to Fedora qubes: ${FEDORA_TEMPLATEVMS[*]:-(none)},
  - to Debian qubes : ${DEBIAN_TEMPLATEVMS[*]:-(none)},
  - in dom0: adding the demo repo, importing RPM key, installing the "buskill" package from the demo repo.
EOF

WORKDIR="$(mktemp -d)"

# Fedora-flavored TemplateVMs
if [ ${#FEDORA_TEMPLATEVMS[@]} -gt 0 ]; then
  copy_file_from_src_qube "$FEDORA_TEMPLATEVM_REPO_FILE"
  for VM in "${FEDORA_TEMPLATEVMS[@]}"; do
    echo "Installing "$FEDORA_TEMPLATEVM_REPO_FILE" in $VM..."
    install_file_as_root "$VM" "$FEDORA_TEMPLATEVM_REPO_FILE" "/etc/yum.repos.d/$FEDORA_TEMPLATEVM_REPO_FILE"
    echo "Configured BusKill repo for Fedora TemplateVM in $VM"
  done
fi

# Debian-flavored TemplateVMs
if [ ${#DEBIAN_TEMPLATEVMS[@]} -gt 0 ]; then
  copy_file_from_src_qube "$DEBIAN_TEMPLATEVM_REPO_FILE"
  copy_file_from_src_qube "$GPG_KEY_FILE"
  for VM in "${DEBIAN_TEMPLATEVMS[@]}"; do
    echo "Installing signing key $GPG_KEY_FILE (yes, it **is** named 'RPM'!) in $VM"
    qvm-run --pass-io -u root "$VM" "gpg --dearmor > '/usr/share/keyrings/qubes-buskill.gpg'" < "${WORKDIR}/${GPG_KEY_FILE}" # direct dearmor without copying
    echo "Installing apt source "$DEBIAN_TEMPLATEVM_REPO_FILE" in $VM"
    install_file_as_root "$VM" "$DEBIAN_TEMPLATEVM_REPO_FILE" "/etc/apt/sources.list.d/$DEBIAN_TEMPLATEVM_REPO_FILE"
    echo "Configured BusKill apt source in $VM"
  done
fi

# dom0
copy_file_from_src_qube "$GPG_KEY_FILE"
copy_file_from_src_qube "$DOM0_REPO_FILE"

echo "Installing ${DOM0_REPO_FILE} in dom0"
sudo cp "${WORKDIR}/${DOM0_REPO_FILE}" "/etc/yum.repos.d/${DOM0_REPO_FILE}"

echo "Importing the BusKill signing key into the dom0 RPM keyring"
sudo rpm --import "${WORKDIR}/${GPG_KEY_FILE}"

echo "Installing the \"buskill\" package in dom0 (downloading packages from the demo repo)..."
sudo qubes-dom0-update --action=install -y buskill

