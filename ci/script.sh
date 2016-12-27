# `script` phase: you usually build, test and generate docs in this phase

set -ex

. $(dirname $0)/utils.sh

# PROTIP Always pass `--target $TARGET` to cargo commands, this makes cargo output build artifacts
# to target/$TARGET/{debug,release} which can reduce the number of needed conditionals in the
# `before_deploy`/packaging phase
run_test_suite() {
    case $TARGET in
        # configure emulation for transparent execution of foreign binaries
        aarch64-unknown-linux-gnu)
            export QEMU_CMD='qemu-aarch64 -L /usr/aarch64-linux-gnu'
            ;;
        arm*-unknown-linux-gnueabihf)
            export QEMU_CMD='qemu-arm -L /usr/arm-linux-gnueabihf'
            ;;
        *)
            ;;
    esac

    if [ ! -z "$QEMU_LD_PREFIX" ]; then
        # Run tests on a single thread when using QEMU user emulation
        export RUST_TEST_THREADS=1
    fi

    cargo build --target $TARGET --verbose

    # cargo test should™ just run if we request qemu-user-static and
    # binfmt-support, but the test crashes. Since that requires sudo and that
    # makes it run on even more ancient host than otherwise, we run the tests
    # manually..
    # nothing to run in a library
    if [ -n "$QEMU_CMD" ]; then
	cargo test --target $TARGET --no-run
	find target/$TARGET/debug -maxdepth 1 -executable -type f -exec $QEMU_CMD '{}' ';'
    else
	cargo test --target $TARGET
    fi

    # sanity check the file type
    # TODO: non-deterministic, unfortunately: file target/$TARGET/debug/hello
}

main() {
    run_test_suite
}

main
