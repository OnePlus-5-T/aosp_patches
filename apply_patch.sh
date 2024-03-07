#!/bin/bash

# Check if the aosp tag has been provided
if [ $# -eq 0 ]; then
  echo "Error: Please provide the AOSP tag - for example android-13.0.0_r52"
  exit 1
fi

aosp_tag="$1"
# Main directory
root_dir="$(dirname "$(pwd)")"

patch_dir="aosp_patches"

# Find all patch files in directory "a" and its subdirectories
patch_files=$(find "$root_dir/$patch_dir" -name "*.patch")

# Loop through each patch file found
for patch_file in $patch_files; do
  # Extract the relative path of the patch file from "$root_dir/a"
  relative_path="${patch_file#$root_dir/$patch_dir/}"

  # Get the project name from the parent subdirectory
  project_name="${relative_path%/*}"

  # Check if the project exists in the main directory
  if [ -d "$root_dir/$project_name" ]; then
    echo "Applying patch $patch_file to $project_name"

    if [ ! -e "$root_dir/$project_name/.patch_applied" ]; then
      cd "$root_dir/$project_name" && git checkout .
      if [ $? -eq 0 ]; then
        touch "$root_dir/$project_name/.patch_applied"
        echo "Initial checkout successful. Patch will be applied."
      else
        echo "Initial checkout failed. Skipping patch for $project_name."
        continue
      fi
    else
      echo "Patch already applied for $project_name. Proceeding to the next patch."
    fi

    git fetch --unshallow aosp
    git checkout "$aosp_tag"
    if [ $? -eq 0 ]; then
      echo "Checked out AOSP tag $aosp_tag successfully."
    else
      echo "Failed to checkout AOSP tag $aosp_tag. Skipping patch for $project_name."
      continue
    fi

    git apply "$patch_file"
    if [ $? -eq 0 ]; then
      echo "Patch applied successfully."
    else
      echo "Patch failed to apply. Skipping patch for $project_name."
      continue
    fi
  else
    echo "Error: Project $project_name does not exist in the main directory."
  fi
done

# Remove .patch_applied file before exiting
for patch_file in $patch_files; do
  relative_path="${patch_file#$root_dir/$patch_dir/}"
  project_name="${relative_path%/*}"
  if [ -e "$root_dir/$project_name/.patch_applied" ]; then
    rm "$root_dir/$project_name/.patch_applied"
  fi
done
