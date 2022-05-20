function cargo-build-wasm
    set -f tdir ./target/wasm32-unknown-unknown/release/

    if test (count $tdir*.wasm) -eq 1
        set -f twasm (find $tdir*.wasm)
        echo Found $twasm
        cargo build --release --target wasm32-unknown-unknown
        wasm-bindgen --out-dir ./out/ --target web $twasm

    else
        echo Failed to find output in $tdir
    end
end
