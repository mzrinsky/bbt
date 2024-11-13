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

