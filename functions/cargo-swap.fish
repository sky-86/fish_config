function cargo-swap -a new
    ### checks if $new is not blank
    if test -z $new
        echo Please provide an extension
        return
    end

    ### and if it exists
    if test -e Cargo.toml.$new 
        echo The provdied extension already exists
        return
    end

    ### Checks if cargo.toml exists
    if test -e Cargo.toml
        set -f newfile Cargo.toml.$new

        ### only one cargo swap, so can auto swap
        if test (count Cargo.toml.*) -eq 1
            set -f oldfile (find Cargo.toml.*)

        ### Need to ask user for swap file
        else
            echo Multiple swap files, please specify extension:
            set -f in temp

            ### while user input is not blank
            while test -n $in;
                echo Please specify a file extension:;
                read -f in
                if test -e Cargo.toml.$in
                    set -f oldfile Cargo.toml.$in
                    break
               end
            end
        end
        mv Cargo.toml $newfile
        echo Moved Cargo.toml to $newfile

        mv $oldfile Cargo.toml
        echo Moved $oldfile to Cargo.toml
    end
end
