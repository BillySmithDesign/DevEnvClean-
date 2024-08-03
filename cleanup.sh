#!/bin/bash

# Variables to track total files cleaned and storage space reduced
TOTAL_FILES_CLEANED=0
TOTAL_SPACE_REDUCED=0

# Function to print section headers
print_header() {
  printf "\n\e[1;34m%s\e[0m\n" "$1"
  printf "\e[1;34m%s\e[0m\n" "===============================\n"
}

# Function to update counters
update_counters() {
  local files_cleaned=$1
  local space_reduced=$2
  TOTAL_FILES_CLEANED=$((TOTAL_FILES_CLEANED + files_cleaned))
  TOTAL_SPACE_REDUCED=$((TOTAL_SPACE_REDUCED + space_reduced))
}

# Function to clean up and track files and space
cleanup_with_tracking() {
  local find_command=$1
  local description=$2
  local files_cleaned=$(eval "$find_command" | wc -l)
  local space_reduced=$(eval "$find_command" | xargs du -k | awk '{total += $1} END {print total}')
  eval "$find_command" | xargs rm -f
  printf "✔ %s: %d files cleaned, %d KB space reduced\n" "$description" "$files_cleaned" "$space_reduced"
  update_counters "$files_cleaned" "$space_reduced"
}

# Function to remove virtual environments in project directories
clean_virtualenvs() {
  print_header "Cleaning Virtual Environments"
  PROJECTS_DIR=~/projects
  echo "Checking $PROJECTS_DIR for virtual environments..."
  for dir in $PROJECTS_DIR/*; do
    if [ -d "$dir/env" ]; then
      local space_reduced=$(du -k "$dir/env" | awk '{print $1}')
      rm -rf "$dir/env"
      printf "✔ $dir/env removed, %d KB space reduced\n" "$space_reduced"
      update_counters 1 "$space_reduced"
    fi
  done
}

# Function to clean up Homebrew
clean_homebrew() {
  print_header "Cleaning Homebrew"
  echo "Cleaning up Homebrew..."
  local space_before=$(df -k /usr/local | tail -1 | awk '{print $4}')
  brew cleanup
  brew autoremove
  local space_after=$(df -k /usr/local | tail -1 | awk '{print $4}')
  local space_reduced=$((space_before - space_after))
  echo "✔ Homebrew cleaned, $space_reduced KB space reduced"
  update_counters 1 "$space_reduced"
}

# Function to clear pip cache
clean_pip_cache() {
  print_header "Cleaning pip Cache"
  echo "Clearing pip cache..."
  cleanup_with_tracking "pip cache purge" "pip cache"
}

# Function to remove temporary files
clean_temp_files() {
  print_header "Removing Temporary Files"
  echo "Removing temporary files..."
  local space_reduced=$(du -k /tmp | awk '{print $1}')
  rm -rf /tmp/*
  echo "✔ Temporary files removed, $space_reduced KB space reduced"
  update_counters 1 "$space_reduced"
}

# Function to clear system cache (for macOS)
clean_system_cache() {
  print_header "Clearing System Cache"
  echo "Clearing system cache..."
  local space_before=$(df -k ~ | tail -1 | awk '{print $4}')
  sudo rm -rf ~/Library/Caches/*
  sudo rm -rf /Library/Caches/*
  local space_after=$(df -k ~ | tail -1 | awk '{print $4}')
  local space_reduced=$((space_before - space_after))
  echo "✔ System cache cleared, $space_reduced KB space reduced"
  update_counters 1 "$space_reduced"
}

# Function to clear npm cache and remove global packages
clean_npm() {
  print_header "Cleaning npm"
  echo "Clearing npm cache..."
  cleanup_with_tracking "npm cache clean --force" "npm cache"
  echo "Removing global npm packages..."
  cleanup_with_tracking "npm ls -g --depth=0 --parseable | grep -v '/npm$' | xargs npm -g rm" "global npm packages"
}

# Function to clean zsh history and cache
clean_zsh() {
  print_header "Cleaning zsh"
  echo "Cleaning zsh history and cache..."
  local files_cleaned=$(find ~/.zsh_history ~/.zsh/cache -type f | wc -l)
  local space_reduced=$(du -k ~/.zsh_history ~/.zsh/cache | awk '{total += $1} END {print total}')
  rm -f ~/.zsh_history
  rm -rf ~/.zsh/cache
  mkdir -p ~/.zsh/cache
  printf "✔ zsh history and cache cleaned, %d files cleaned, %d KB space reduced\n" "$files_cleaned" "$space_reduced"
  update_counters "$files_cleaned" "$space_reduced"
}

# Function to clean Docker
clean_docker() {
  print_header "Cleaning Docker"
  echo "Cleaning Docker..."
  local space_before=$(df -k /var/lib/docker | tail -1 | awk '{print $4}')
  docker system prune -af
  docker volume prune -f
  docker network prune -f
  local space_after=$(df -k /var/lib/docker | tail -1 | awk '{print $4}')
  local space_reduced=$((space_before - space_after))
  echo "✔ Docker cleaned, $space_reduced KB space reduced"
  update_counters 1 "$space_reduced"
}

# Function to remove old log files
clean_logs() {
  print_header "Cleaning Log Files"
  LOG_DIR=~/logs
  echo "Removing old log files in $LOG_DIR..."
  cleanup_with_tracking "find $LOG_DIR -type f -name '*.log' -mtime +30" "old log files"
}

# Function to clean cache for common tools
clean_tool_caches() {
  print_header "Cleaning Tool Caches"
  echo "Cleaning Yarn cache..."
  cleanup_with_tracking "yarn cache clean" "Yarn cache"
  echo "Cleaning Composer cache..."
  cleanup_with_tracking "composer clear-cache" "Composer cache"
  echo "Cleaning Gem cache..."
  cleanup_with_tracking "gem cleanup" "Gem cache"
}

# Function to remove old Python bytecode files
clean_python_bytecode() {
  print_header "Cleaning Python Bytecode"
  echo "Removing old Python bytecode files..."
  cleanup_with_tracking "find . -name '*.pyc' -not -path './Pictures/Photos Library.photoslibrary/*' -not -path './Library/Application Support/MobileSync/*'" "Python bytecode files"
  cleanup_with_tracking "find . -name '__pycache__' -not -path './Pictures/Photos Library.photoslibrary/*' -not -path './Library/Application Support/MobileSync/*'" "Python __pycache__ directories"
}

# Function to clean Rust Cargo cache
clean_cargo_cache() {
  print_header "Cleaning Rust Cargo Cache"
  echo "Cleaning Rust Cargo cache..."
  cargo clean
  echo "✔ Rust Cargo cache cleaned"
  update_counters 1 0
}

# Function to clean Xcode derived data
clean_xcode() {
  print_header "Cleaning Xcode Derived Data"
  echo "Removing Xcode derived data..."
  local space_reduced=$(du -k ~/Library/Developer/Xcode/DerivedData | awk '{print $1}')
  rm -rf ~/Library/Developer/Xcode/DerivedData/*
  echo "✔ Xcode derived data removed, $space_reduced KB space reduced"
  update_counters 1 "$space_reduced"
}

# Function to remove node_modules directories in project folders
clean_node_modules() {
  print_header "Cleaning node_modules Directories"
  echo "Checking $PROJECTS_DIR for node_modules directories..."
  PROJECTS_DIR=~/projects
  for dir in $PROJECTS_DIR/*; do
    if [ -d "$dir/node_modules" ]; then
      local space_reduced=$(du -k "$dir/node_modules" | awk '{print $1}')
      rm -rf "$dir/node_modules"
      echo "✔ $dir/node_modules removed, $space_reduced KB space reduced"
      update_counters 1 "$space_reduced"
    fi
  done
}

# Function to clean VSCode workspace storage
clean_vscode() {
  print_header "Cleaning VSCode Workspace Storage"
  echo "Removing VSCode workspace storage..."
  local space_reduced=$(du -k ~/Library/Application\ Support/Code/User/workspaceStorage | awk '{print $1}')
  rm -rf ~/Library/Application\ Support/Code/User/workspaceStorage/*
  echo "✔ VSCode workspace storage removed, $space_reduced KB space reduced"
  update_counters 1 "$space_reduced"
}

# Function to clean up git repositories
clean_git() {
  print_header "Cleaning Git Repositories"
  echo "Cleaning untracked files in git repositories..."
  PROJECTS_DIR=~/projects
  for dir in $PROJECTS_DIR/*; do
    if [ -d "$dir/.git" ]; then
      local space_before=$(du -k "$dir" | awk '{print $1}')
      echo "Cleaning $dir"
      cd $dir
      git clean -fd
      git gc
      cd -
      local space_after=$(du -k "$dir" | awk '{print $1}')
      local space_reduced=$((space_before - space_after))
      echo "✔ $dir cleaned, $space_reduced KB space reduced"
      update_counters 1 "$space_reduced"
    fi
  done
}

# Run all cleanup functions
clean_virtualenvs
clean_homebrew
clean_pip_cache
clean_temp_files
clean_system_cache
clean_npm
clean_zsh
clean_docker
clean_logs
clean_tool_caches
clean_python_bytecode
clean_cargo_cache
clean_xcode
clean_node_modules
clean_vscode
clean_git

print_header "Cleanup Completed"
echo "✔ Total files cleaned: $TOTAL_FILES_CLEANED"
echo "✔ Total storage space reduced: $((TOTAL_SPACE_REDUCED / 1024)) MB"
