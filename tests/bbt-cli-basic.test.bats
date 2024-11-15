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

  if [ ! -d "tests/output/restore/" ]; then
    mkdir -p "tests/output/restore/"
  fi

  if [ "$(ls -A tests/output/restore/)" ]; then
    rm -r tests/output/restore/*
  fi

	echo '# setup complete' >&3
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
	echo "# check exit status"
	[ "${status}" -ne 0 ]
	[ "${status}" -eq 1 ]

	echo "# check for help message"
	[[ "${output}" =~ "Usage: bbt-cli" ]]
	[[ "${output}" =~ "Options:" ]]
	[[ "${output}" =~ "Commands:" ]]
}

@test "Generate a bash backup script" {

	run main_gen_backup

	[ "${status}" -eq 0 ]
  [ -f "./tests/output/test-backup-script" ]
}

@test "Generate a bash restore script" {

	run main_gen_restore

	[ "${status}" -eq 0 ]
  [ -f "./tests/output/test-restore-script" ]
}

@test "Run test bash backup script" {

  # make a string with the current date.. this could fail if it runs at the wrong second at midnight..
  DATESTR=`date -d now '+%F-*'`

  run main_run_backup

  [ "${status}" -eq 0 ]
  [ -f ./tests/output/backups/test-archive-basename-${DATESTR} ]
  [ -f "./tests/output/backups/latest" ]

  run main_list_backup
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

@test "Run test restore script" {

  DATESTR=`date -d now '+%F-*'`

  run main_run_restore

  [ "${status}" -eq 0 ]
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