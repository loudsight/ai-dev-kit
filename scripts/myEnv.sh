# Source this file (`source scripts/myEnv.sh`) to put your toolchain on PATH in a shell that lacks it, for example an agent's.
# Edit the three lines under "Your toolchain"; the rest is generic.

# --- Your toolchain -------------------------------------------------------------
export JAVA_HOME="${JAVA_HOME:-$HOME/tools/jdk/current}"
MAVEN_HOME="${MAVEN_HOME:-$HOME/tools/maven/current}"
export WORK_ROOT="${WORK_ROOT:-$HOME/work}"
# --------------------------------------------------------------------------------

# Prepend, then drop duplicate PATH entries so repeated sourcing does not grow PATH.
PATH="$JAVA_HOME/bin:$MAVEN_HOME/bin:$PATH"
PATH=$(printf '%s' "$PATH" | awk -v RS=: '!seen[$0]++ { printf "%s%s", sep, $0; sep = ":" }')
export PATH

# Traps this file cannot fix, and that cost time:
#  - In zsh, never name a variable `path`: it is tied to PATH, and assigning it empties PATH.
#  - macOS has no GNU `timeout`. Install coreutils and use `gtimeout`, or avoid it.
