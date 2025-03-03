#!/usr/bin/env bats

setup() {
  load '../node_modules/bats-support/load'
  load '../node_modules/bats-assert/load'
}

setup_file() {
  load '../node_modules/bats-support/load'
  load '../node_modules/bats-assert/load'

  if [ ! -d "tests/output/" ]; then
    mkdir -p "tests/output"
  fi

  if [ ! -d "tests/output/backups-from-remote/" ]; then
    mkdir -p "tests/output/backups-from-remote/"
  fi

  if [ "$(ls -A tests/output/backups-from-remote/)" ]; then
    rm -r tests/output/backups-from-remote/*
  fi

  if [ ! -d "tests/output/restore-from-remote/" ]; then
    mkdir -p "tests/output/restore-from-remote/"
  fi

  if [ "$(ls -A tests/output/restore-from-remote/)" ]; then
    rm -r tests/output/restore-from-remote/*
  fi

  if [ ! -d "tests/data/ssh/" ]; then
    mkdir -p "tests/data/ssh/"
    chmod 700 tests/data/ssh/
  fi

  if [ "$(ls -A tests/data/ssh/)" ]; then
    rm -r tests/data/ssh/*
  fi

  if [ ! -f "tests/data/ssh/testuser-ed25519" ]; then
    ssh-keygen -t ed25519 -C "testuser@example.com" -N "" -f tests/data/ssh/testuser-ed25519
  fi

  run which docker
  echo "Checking for docker command.."
  assert_success

  run docker info
  echo "Checking for running docker.."
  assert_success

  run run_start_ssh_server
  echo "Starting local test ssh server.."
  assert_success

  run run_init_remote_test_data
  echo "Initializing local ssh test data.."
  assert_success
}

teardown_file() {
  docker stop bbt-test-sshd
}

main() {
	./bbt-cli.js
}

main_run_backup_remote() {
  ./tests/output/test-backup-remote-script
}

main_run_backup_to_remote() {
  ./tests/output/test-backup-to-remote-script
}

main_run_backup_from_remote() {
  ./tests/output/test-backup-from-remote-script
}

main_list_backup_remote() {
  ssh -i tests/data/ssh/testuser-ed25519 -o "StrictHostKeyChecking=no" -p 63333 testuser@localhost "tar --list -zf /tmp/tests/output/backups/latest"
}

main_list_backup_to_remote() {
  ssh -i tests/data/ssh/testuser-ed25519 -o "StrictHostKeyChecking=no" -p 63333 testuser@localhost "tar --list -zf /tmp/tests/output/backups-to-remote/latest"
}

main_list_backup_from_remote() {
  tar --list -zf tests/output/backups-from-remote/latest
}

main_run_restore_remote() {
  ./tests/output/test-restore-remote-script
}

main_run_restore_to_remote() {
  ./tests/output/test-restore-to-remote-script
}

main_run_restore_from_remote() {
  ./tests/output/test-restore-from-remote-script
}

main_list_restore_remote() {
  ssh -i tests/data/ssh/testuser-ed25519 -o "StrictHostKeyChecking=no" -p 63333 testuser@localhost "cd /tmp/tests/output/restore-from-remote/ && find ."
}

main_list_restore_to_remote() {
  ssh -i tests/data/ssh/testuser-ed25519 -o "StrictHostKeyChecking=no" -p 63333 testuser@localhost "cd /tmp/tests/output/restore-to-remote/ && find ."
}

main_list_restore_from_remote() {
  local cdir=$(pwd)
  cd tests/output/restore-from-remote/ && find .
  cd ${cdir}
}

run_start_ssh_server() {
  # this is creating dirs owned by root, and probably should not do that..
  local RUNUSERID=$(id -u ${USER})
  local RUNUSERGRPID=$(id -g ${USER})
  docker run -d --rm -p 63333:22 \
    -v $(pwd)/tests/data/ssh/testuser-ed25519.pub:/etc/authorized_keys/testuser:ro \
    -e SSH_USERS="testuser:${RUNUSERID}:${RUNUSERGRPID}" \
    --name bbt-test-sshd \
    mzrinsky/sshd-bbt:latest
  # give the server a moment to start..
  sleep 3
}


run_init_remote_test_data() {
  echo "Initializing test data on local ssh server.."
  ssh -i tests/data/ssh/testuser-ed25519 -o "StrictHostKeyChecking=no" -p 63333 testuser@localhost "mkdir -p /tmp/tests/data/input/"
  ssh -i tests/data/ssh/testuser-ed25519 -o "StrictHostKeyChecking=no" -p 63333 testuser@localhost "mkdir -p /tmp/tests/output/"
  ssh -i tests/data/ssh/testuser-ed25519 -o "StrictHostKeyChecking=no" -p 63333 testuser@localhost "mkdir -p /tmp/tests/output/restore-from-remote/"
  ssh -i tests/data/ssh/testuser-ed25519 -o "StrictHostKeyChecking=no" -p 63333 testuser@localhost "mkdir -p /tmp/tests/output/restore-to-remote/"
  scp -r -i tests/data/ssh/testuser-ed25519 -o "StrictHostKeyChecking=no" -P 63333 tests/data/input/ testuser@localhost:/tmp/tests/data/
}


@test "Generate bash backup scripts for ssh testing" {

	run ./bbt-cli.js -c tests/data/bats-backup-remote-config.json bash-backup -o tests/output/test-backup-remote-script
  assert_success
  [ -f "./tests/output/test-backup-remote-script" ]


  run ./bbt-cli.js -c tests/data/bats-backup-from-remote-config.json bash-backup -o tests/output/test-backup-from-remote-script
  assert_success
  [ -f "./tests/output/test-backup-from-remote-script" ]


  run ./bbt-cli.js -c tests/data/bats-backup-to-remote-config.json bash-backup -o tests/output/test-backup-to-remote-script
  assert_success
  [ -f "./tests/output/test-backup-to-remote-script" ]
}


@test "Generate bash restore scripts for ssh testing" {

  run ./bbt-cli.js -c tests/data/bats-restore-remote-config.json bash-restore -o tests/output/test-restore-remote-script
  assert_success
  [ -f "./tests/output/test-restore-remote-script" ]

  run ./bbt-cli.js -c tests/data/bats-restore-from-remote-config.json bash-restore -o tests/output/test-restore-from-remote-script
  assert_success
  [ -f "./tests/output/test-restore-from-remote-script" ]


  run ./bbt-cli.js -c tests/data/bats-restore-to-remote-config.json bash-restore -o tests/output/test-restore-to-remote-script
  assert_success
  [ -f "./tests/output/test-restore-to-remote-script" ]
}


@test "Run bash remote backup script against local test ssh server" {

  run main_run_backup_remote
  assert_success

  run main_list_backup_remote
  assert_success

  assert_output -p "test-dir-1/"
  assert_output -p "test-dir-1/td1-test-file-1"
  assert_output -p "test-dir-1/td1-test-file-2"
  assert_output -p "test-dir-1/td1-test-file-3"
  assert_output -p "test-dir-2/"
  refute_output "test-dir-2/td2-test-file-1"
  assert_output -p "test-dir-2/td2-test-file-2"
  refute_output "test-dir-2/td2-test-file-3"
  assert_output -p "test-dir-3/"
  assert_output -p "test-dir-3/td3-test-file-1"
  assert_output -p "test-dir-3/td3-test-file-2"
  assert_output -p "test-dir-3/td3-test-file-3"
  assert_output -p "test-file-1"
  assert_output -p "test-file-2"
  assert_output -p "test-file-3"
  refute_output "test-file-4"
  assert_output -p "test-file-5"

}


@test "Run bash remote backup script (to remote) against local test ssh server" {

  run main_run_backup_to_remote
  assert_success

  run main_list_backup_to_remote
  assert_success

  assert_output -p "test-dir-1/"
  assert_output -p "test-dir-1/td1-test-file-1"
  assert_output -p "test-dir-1/td1-test-file-2"
  assert_output -p "test-dir-1/td1-test-file-3"
  assert_output -p "test-dir-2/"
  refute_output "test-dir-2/td2-test-file-1"
  assert_output -p "test-dir-2/td2-test-file-2"
  refute_output "test-dir-2/td2-test-file-3"
  assert_output -p "test-dir-3/"
  assert_output -p "test-dir-3/td3-test-file-1"
  assert_output -p "test-dir-3/td3-test-file-2"
  assert_output -p "test-dir-3/td3-test-file-3"
  assert_output -p "test-file-1"
  assert_output -p "test-file-2"
  assert_output -p "test-file-3"
  refute_output "test-file-4"
  assert_output -p "test-file-5"

}

@test "Run bash remote backup script (from remote) against local test ssh server" {

  run main_run_backup_from_remote
  assert_success

  run main_list_backup_from_remote
  assert_success

  assert_output -p "test-dir-1/"
  assert_output -p "test-dir-1/td1-test-file-1"
  assert_output -p "test-dir-1/td1-test-file-2"
  assert_output -p "test-dir-1/td1-test-file-3"
  assert_output -p "test-dir-2/"
  refute_output "test-dir-2/td2-test-file-1"
  assert_output -p "test-dir-2/td2-test-file-2"
  refute_output "test-dir-2/td2-test-file-3"
  assert_output -p "test-dir-3/"
  assert_output -p "test-dir-3/td3-test-file-1"
  assert_output -p "test-dir-3/td3-test-file-2"
  assert_output -p "test-dir-3/td3-test-file-3"
  assert_output -p "test-file-1"
  assert_output -p "test-file-2"
  assert_output -p "test-file-3"
  refute_output "test-file-4"
  assert_output -p "test-file-5"

}


@test "Run bash remote restore script against local test ssh server" {

  run main_run_restore_remote
  assert_success

  run main_list_restore_remote
  assert_success

  assert_output -p "test-dir-1"
  assert_output -p "test-dir-1/td1-test-file-1"
  assert_output -p "test-dir-1/td1-test-file-2"
  assert_output -p "test-dir-1/td1-test-file-3"
  assert_output -p "test-dir-2"
  refute_output "test-dir-2/td2-test-file-1"
  refute_output "test-dir-2/td2-test-file-2"
  refute_output "test-dir-2/td2-test-file-3"
  refute_output "test-dir-3/"
  refute_output "test-dir-3/td3-test-file-1"
  refute_output "test-dir-3/td3-test-file-2"
  refute_output "test-dir-3/td3-test-file-3"
  assert_output -p "test-file-1"
  assert_output -p "test-file-2"
  assert_output -p "test-file-3"
  refute_output "test-file-4"
  refute_output "test-file-5"

}

@test "Run bash remote restore script (to remote) against local test ssh server" {

  run main_run_restore_to_remote
  assert_success

  run main_list_restore_to_remote
  assert_success

  assert_output -p "test-dir-1"
  assert_output -p "test-dir-1/td1-test-file-1"
  assert_output -p "test-dir-1/td1-test-file-2"
  assert_output -p "test-dir-1/td1-test-file-3"
  assert_output -p "test-dir-2"
  refute_output "test-dir-2/td2-test-file-1"
  refute_output "test-dir-2/td2-test-file-2"
  refute_output "test-dir-2/td2-test-file-3"
  refute_output "test-dir-3/"
  refute_output "test-dir-3/td3-test-file-1"
  refute_output "test-dir-3/td3-test-file-2"
  refute_output "test-dir-3/td3-test-file-3"
  assert_output -p "test-file-1"
  assert_output -p "test-file-2"
  assert_output -p "test-file-3"
  refute_output "test-file-4"
  refute_output "test-file-5"

}

@test "Run bash remote restore script (from remote) against local test ssh server" {

  run main_run_restore_from_remote
  assert_success

  run main_list_restore_from_remote
  assert_success

  assert_output -p "test-dir-1"
  assert_output -p "test-dir-1/td1-test-file-1"
  assert_output -p "test-dir-1/td1-test-file-2"
  assert_output -p "test-dir-1/td1-test-file-3"
  assert_output -p "test-dir-2"
  refute_output "test-dir-2/td2-test-file-1"
  refute_output "test-dir-2/td2-test-file-2"
  refute_output "test-dir-2/td2-test-file-3"
  refute_output "test-dir-3/"
  refute_output "test-dir-3/td3-test-file-1"
  refute_output "test-dir-3/td3-test-file-2"
  refute_output "test-dir-3/td3-test-file-3"
  assert_output -p "test-file-1"
  assert_output -p "test-file-2"
  assert_output -p "test-file-3"
  refute_output "test-file-4"
  refute_output "test-file-5"

}
