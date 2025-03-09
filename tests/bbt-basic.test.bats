#!/usr/bin/env bats

setup() {
  load '../node_modules/bats-support/load'
  load '../node_modules/bats-assert/load'
}

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

  if [ ! -d "tests/output/restore/" ]; then
    mkdir -p "tests/output/restore/"
  fi

  if [ "$(ls -A tests/output/restore/)" ]; then
    rm -r tests/output/restore/*
  fi
}

main() {
	./bbt.js
}

main_gen_backup() {
	./bbt.js bash-backup -c tests/data/bats-backup-config.json -o tests/output/test-backup-script
}

main_gen_restore() {
	./bbt.js bash-restore -c tests/data/bats-restore-config.json -o tests/output/test-restore-script
}

main_run_backup() {
  ./tests/output/test-backup-script
}

main_list_backup() {
  tar --list -zf ./tests/output/backups/latest
}

main_list_backup_snapshots() {
  ls -la ./tests/output/backups/test-archive-basename-*.tar.gz
}

main_count_backup_snapshots() {
  ls -la ./tests/output/backups/test-archive-basename-*.tar.gz | wc -l
}

main_run_restore() {
  ./tests/output/test-restore-script
}

@test "fail with no config file." {

	run main
  assert_failure

  assert_output -p "Usage: bbt"
  assert_output -p "Options:"
  assert_output -p "Commands:"
}

@test "Generate a bash backup script" {

	run main_gen_backup
	assert_success

  [ -f "./tests/output/test-backup-script" ]
}

@test "Generate a bash restore script" {

	run main_gen_restore
  assert_success

  [ -f "./tests/output/test-restore-script" ]
}

@test "Run test bash backup script" {

  run main_run_backup
  assert_success
  sleep 1 # delay so the timestamps on the snapshots are at least 1 second apart..

  run main_list_backup
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

  # verify the permissions
  run main_list_backup_snapshots
  assert_success
  assert_output -p "test-archive-basename"
  assert_output -p "-rw-rw----"

  run main_count_backup_snapshots
  assert_success
  assert_output -p "1"

  [ -f "./tests/output/backups/latest" ]


  # run the backup more times, to test archiveKeepLast functionality
  run main_run_backup
  assert_success
  sleep 1 # delay so the timestamps on the snapshots are at least 1 second apart..

  run main_run_backup
  assert_success
  sleep 1 # delay so the timestamps on the snapshots are at least 1 second apart..

  # verify there are 3 snapshots
  run main_count_backup_snapshots
  assert_success
  assert_output -p "3"

  # and that the latest link is still there..
  [ -f "./tests/output/backups/latest" ]

  # run a 4th time
  run main_run_backup
  assert_success

  # verify there are still only 3 snapshots
  run main_count_backup_snapshots
  assert_success
  assert_output -p "3"

  # and that the latest link is still there..
  [ -f "./tests/output/backups/latest" ]
}

@test "Run test restore script" {

  run main_run_restore

  assert_success
  [ -d "./tests/output/restore/test-dir-1" ]
  [ -f "./tests/output/restore/test-dir-1/td1-test-file-1" ]
  [ -f "./tests/output/restore/test-dir-1/td1-test-file-2" ]
  [ -f "./tests/output/restore/test-dir-1/td1-test-file-3" ]
  [ -d "./tests/output/restore/test-dir-2" ]
  [ -f "./tests/output/restore/test-file-1" ]
  [ -f "./tests/output/restore/test-file-2" ]
  [ -f "./tests/output/restore/test-file-3" ]
  [ ! -d "./tests/output/restore/test-dir-3" ]
  [ ! -f "./tests/output/restore/test-dir-2/td1-test-file-1" ]
  [ ! -f "./tests/output/restore/test-dir-2/td1-test-file-2" ]
  [ ! -f "./tests/output/restore/test-dir-2/td1-test-file-3" ]
}
