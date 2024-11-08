#!/bin/bash

# Load dependencies from a file
declare -a dependencies
while IFS=: read -r project deps; do
    # Replace commas with spaces for easier handling in arrays
    dependencies+=("$project:${deps//,/ }")
done < dependencies.txt

# Function to get dependencies for a project
getDependencies() {
    local project="$1"
    local visited="$2"

    # Check if project is already visited to avoid infinite loops
    if [[ "$visited" =~ "$project" ]]; then
        return
    fi

    # Add project to visited list
    visited+=" $project"

    # Find dependencies of the project
    for entry in "${dependencies[@]}"; do
        local key="${entry%%:*}"
        local deps="${entry#*:}"
        if [[ "$key" == "$project" && -n "$deps" ]]; then
            for dep in $deps; do
                echo "$dep"
                # Recursively find dependencies for each dependency
                getDependencies "$dep" "$visited"
            done
        fi
    done
}

# Function to get all projects that depend on a specific project, with duplicates removed
getDependentProjects() {
    local target="$1"
    local -a results=()

    for entry in "${dependencies[@]}"; do
        local project="${entry%%:*}"
        local deps="${entry#*:}"
        if [[ "$deps" =~ "$target" ]]; then
            # Add the project to results if it's not already in the array
            if [[ ! " ${results[@]} " =~ " $project " ]]; then
                results+=("$project")
                # Recursively find all projects that depend on this project
                local sub_deps
                sub_deps=$(getDependentProjects "$project")
                # Add unique results from sub_deps to the main results array
                for sub_dep in $sub_deps; do
                    if [[ ! " ${results[@]} " =~ " $sub_dep " ]]; then
                        results+=("$sub_dep")
                    fi
                done
            fi
        fi
    done

    # Print unique results
    printf "%s\n" "${results[@]}" | sort -u
}

# Check if the script received a parameter
if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: $0 <option> <project_name>"
    echo "Options:"
    echo "  dependencies - List all dependencies for the project"
    echo "  dependents   - List all projects that depend on the project"
    exit 1
fi

# Get the parameter and call the appropriate function
option="$1"
project="$2"

case "$option" in
    dependencies)
        echo "Dependencies for $project:"
        getDependencies "$project" "" | sort -u
        ;;
    dependents)
        echo "Projects that depend on $project:"
        getDependentProjects "$project"
        ;;
    *)
        echo "Invalid option. Use 'dependencies' or 'dependents'."
        exit 1
        ;;
esac
