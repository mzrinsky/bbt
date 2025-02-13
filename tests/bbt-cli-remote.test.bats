#!/usr/bin/env bats

setup_file() {
  if [ ! -d "tests/output/" ]; then
    mkdir -p "tests/output"
  fi

  if [ "$(ls -A tests/output)" ]; then
    rm -r tests/output/*
  fi

  if [ ! -d "tests/output/backups/" ]; then
    mkdir -p "tests/output/backups/"
  fi

  if [ "$(ls -A tests/output/backups/)" ]; then
    rm -r tests/output/backups/*
  fi

  if [ ! -d "tests/output/backups-from-remote/" ]; then
    mkdir -p "tests/output/backups-from-remote/"
  fi

  if [ "$(ls -A tests/output/backups-from-remote/)" ]; then
    rm -r tests/output/backups-from-remote/*
  fi

  if [ ! -d "tests/output/restore/" ]; then
    mkdir -p "tests/output/restore/"
  fi

  if [ "$(ls -A tests/output/restore/)" ]; then
    rm -r tests/output/restore/*
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
  [ "${status}" -eq 0 ]

  run docker info
  echo "Checking for running docker.."
  [ "${status}" -eq 0 ]

  run run_start_ssh_server
  echo "starting ssh server.."
  echo "${output}"
  [ "${status}" -eq 0 ]

  run run_init_remote_test_data
  echo "${output}"
  [ "${status}" -eq 0 ]

	echo '# setup complete' >&3
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
  ssh -i tests/data/ssh/testuser-ed25519 -p 63333 testuser@localhost "tar --list -f /tmp/tests/output/backups/latest"
}

main_list_backup_to_remote() {
  ssh -i tests/data/ssh/testuser-ed25519 -p 63333 testuser@localhost "tar --list -f /tmp/tests/output/backups-to-remote/latest"
}

main_list_backup_from_remote() {
  tar --list -f tests/output/backups-from-remote/latest
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

run_start_ssh_server() {
  local RUNUSERID=$(id -u ${USER})
  local RUNUSERGRPID=$(id -g ${USER})
  docker run -d --rm -p 63333:22 \
    -v $(pwd)/tests/data/ssh/testuser-ed25519.pub:/etc/authorized_keys/testuser:ro \
    -v $(pwd)/keys/:/etc/ssh/keys \
    -v $(pwd)/data/:/data/ \
    -e SSH_USERS="testuser:${RUNUSERID}:${RUNUSERGRPID}" \
    --name bbt-test-sshd \
    mzrinsky/sshd-bbt:latest
  # give the server a moment to start..
  sleep 2
}


run_init_remote_test_data() {
  ssh -i tests/data/ssh/testuser-ed25519 -p 63333 testuser@localhost "mkdir -p /tmp/tests/data/input/"
  ssh -i tests/data/ssh/testuser-ed25519 -p 63333 testuser@localhost "mkdir -p /tmp/tests/output/"
  scp -r -i tests/data/ssh/testuser-ed25519 -P 63333 tests/data/input/ testuser@localhost:/tmp/tests/data/
}


@test "Generate bash backup scripts for ssh testing" {

	run ./bbt-cli.js -c tests/data/bats-backup-remote-config.json bash-backup -o tests/output/test-backup-remote-script
  echo "${output}"
	[ "${status}" -eq 0 ]
  [ -f "./tests/output/test-backup-remote-script" ]


  run ./bbt-cli.js -c tests/data/bats-backup-from-remote-config.json bash-backup -o tests/output/test-backup-from-remote-script
  echo "${output}"
  [ "${status}" -eq 0 ]
  [ -f "./tests/output/test-backup-from-remote-script" ]


  run ./bbt-cli.js -c tests/data/bats-backup-to-remote-config.json bash-backup -o tests/output/test-backup-to-remote-script
  echo "${output}"
  [ "${status}" -eq 0 ]
  [ -f "./tests/output/test-backup-to-remote-script" ]
}


@test "Generate bash restore scripts for ssh testing" {

  run ./bbt-cli.js -c tests/data/bats-restore-remote-config.json bash-restore -o tests/output/test-restore-remote-script
  echo "${output}"
  [ "${status}" -eq 0 ]
  [ -f "./tests/output/test-restore-remote-script" ]

  run ./bbt-cli.js -c tests/data/bats-restore-from-remote-config.json bash-restore -o tests/output/test-restore-from-remote-script
  echo "${output}"
  [ "${status}" -eq 0 ]
  [ -f "./tests/output/test-restore-from-remote-script" ]


  run ./bbt-cli.js -c tests/data/bats-restore-to-remote-config.json bash-restore -o tests/output/test-restore-to-remote-script
  echo "${output}"
	[ "${status}" -eq 0 ]
  [ -f "./tests/output/test-restore-to-remote-script" ]
}


@test "Run bash remote backup script against local test ssh server" {

  run main_run_backup_remote
  echo "${output}"
  [ "${status}" -eq 0 ]

  run main_list_backup_remote
  echo "verify backup archive contents"
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "test-dir-1/" ]]
  [[ "${output}" =~ "test-dir-1/td1-test-file-1" ]]
  [[ "${output}" =~ "test-dir-1/td1-test-file-2" ]]
  [[ "${output}" =~ "test-dir-1/td1-test-file-3" ]]
  [[ "${output}" =~ "test-dir-2/" ]]
  [[ ! "${output}" =~ "test-dir-2/td2-test-file-1" ]]
  [[ "${output}" =~ "test-dir-2/td2-test-file-2" ]]
  [[ ! "${output}" =~ "test-dir-2/td2-test-file-3" ]]
  [[ "${output}" =~ "test-dir-3/" ]]
  [[ "${output}" =~ "test-dir-3/td3-test-file-1" ]]
  [[ "${output}" =~ "test-dir-3/td3-test-file-2" ]]
  [[ "${output}" =~ "test-dir-3/td3-test-file-3" ]]
  [[ "${output}" =~ "test-file-1" ]]
  [[ "${output}" =~ "test-file-2" ]]
  [[ "${output}" =~ "test-file-3" ]]
  [[ ! "${output}" =~ "test-file-4" ]]
  [[ "${output}" =~ "test-file-5" ]]

}


@test "Run bash remote backup script (to remote) against local test ssh server" {

  run main_run_backup_to_remote
  echo "${output}"
  [ "${status}" -eq 0 ]

  run main_list_backup_to_remote
  echo "verify backup archive contents"
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "test-dir-1/" ]]
  [[ "${output}" =~ "test-dir-1/td1-test-file-1" ]]
  [[ "${output}" =~ "test-dir-1/td1-test-file-2" ]]
  [[ "${output}" =~ "test-dir-1/td1-test-file-3" ]]
  [[ "${output}" =~ "test-dir-2/" ]]
  [[ ! "${output}" =~ "test-dir-2/td2-test-file-1" ]]
  [[ "${output}" =~ "test-dir-2/td2-test-file-2" ]]
  [[ ! "${output}" =~ "test-dir-2/td2-test-file-3" ]]
  [[ "${output}" =~ "test-dir-3/" ]]
  [[ "${output}" =~ "test-dir-3/td3-test-file-1" ]]
  [[ "${output}" =~ "test-dir-3/td3-test-file-2" ]]
  [[ "${output}" =~ "test-dir-3/td3-test-file-3" ]]
  [[ "${output}" =~ "test-file-1" ]]
  [[ "${output}" =~ "test-file-2" ]]
  [[ "${output}" =~ "test-file-3" ]]
  [[ ! "${output}" =~ "test-file-4" ]]
  [[ "${output}" =~ "test-file-5" ]]

}

@test "Run bash remote backup script (from remote) against local test ssh server" {

  run main_run_backup_from_remote
  echo "${output}"
  [ "${status}" -eq 0 ]

  run main_list_backup_from_remote
  echo "verify backup archive contents"
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "test-dir-1/" ]]
  [[ "${output}" =~ "test-dir-1/td1-test-file-1" ]]
  [[ "${output}" =~ "test-dir-1/td1-test-file-2" ]]
  [[ "${output}" =~ "test-dir-1/td1-test-file-3" ]]
  [[ "${output}" =~ "test-dir-2/" ]]
  [[ ! "${output}" =~ "test-dir-2/td2-test-file-1" ]]
  [[ "${output}" =~ "test-dir-2/td2-test-file-2" ]]
  [[ ! "${output}" =~ "test-dir-2/td2-test-file-3" ]]
  [[ "${output}" =~ "test-dir-3/" ]]
  [[ "${output}" =~ "test-dir-3/td3-test-file-1" ]]
  [[ "${output}" =~ "test-dir-3/td3-test-file-2" ]]
  [[ "${output}" =~ "test-dir-3/td3-test-file-3" ]]
  [[ "${output}" =~ "test-file-1" ]]
  [[ "${output}" =~ "test-file-2" ]]
  [[ "${output}" =~ "test-file-3" ]]
  [[ ! "${output}" =~ "test-file-4" ]]
  [[ "${output}" =~ "test-file-5" ]]

}