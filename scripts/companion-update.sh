companion-update() {
    repo_url="https://github.com/abhijayrajvansh/openclaw-companion-generator-nsfw.git"
    temp_dir="temp_repo"

    echo "Which companion do you want to update?"
    read companion_name

    if [ -z "$companion_name" ]; then
        echo "Companion name is required."
        return 1
    fi

    rm -rf "$temp_dir"

    git clone --depth=1 "$repo_url" "$temp_dir" || return 1

    companion_path="$temp_dir/$companion_name"

    if [ ! -d "$companion_path" ]; then
        echo "Companion '$companion_name' not found."
        echo "Available companions:"
        find "$temp_dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
        rm -rf "$temp_dir"
        return 1
    fi

    cp -R "$companion_path"/. ./

    rm -rf "$temp_dir"

    echo "Updated companion '$companion_name' files here."
}