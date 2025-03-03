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
	./bbt-cli.js
}

main_gen_backup() {
	./bbt-cli.js -c tests/data/bats-backup-config.json bash-backup -o tests/output/test-backup-script
}

main_gen_restore() {
	./bbt-cli.js -c tests/data/bats-restore-config.json bash-restore -o tests/output/test-restore-script
}

main_run_backup() {
  ./tests/output/test-backup-script
}

main_list_backup() {
  tar --list -f ./tests/output/backups/latest
}

main_run_restore() {
  ./tests/output/test-restore-script
}

@test "fail with no config file." {

	run main
  assert_failure

  assert_output -p "Usage: bbt-cli"
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

  # make a string with the current date.. this could fail if it runs at the wrong second at midnight..
  DATESTR=`date -d now '+%F-*'`

  run main_run_backup
  assert_success

  [ -f ./tests/output/backups/test-archive-basename-${DATESTR} ]

  run find ./tests/output/backups/ -maxdepth 1 -name "test-archive-basename-*" -print -quit
  assert_success
  [ "${output}" != "" ]

  [ -f "./tests/output/backups/latest" ]

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
