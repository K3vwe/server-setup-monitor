# This Script performs the following functions:
# 1. Check if the user exists, if not create the user
# 2. Set a default home directory for the user
# 3. Assign the user to a specific group (e.g., sudo, devops)
# 4. Set up SSH key-based authentication for the new user
# 5. Disable password-based SSH authentication for enhanced security.
# 6. Configure the firewall to allow SSH connections

#/bin/bash
# Exit immediately if a command fails
set -e

# Include logs
exec > >(tee -i /var/log/users.log)
exec 2>&1

# Function to create a user if it doesn't exist
createUser () {
    local username="$1"
    local password="$2"

    # Check if username and password are provided
    if [[ -z "$username" || -z "$password" ]]; then
        echo "Username and password must be provided."
        echo "Usage: createUser <username> <password>"
        return 1
    fi

    # Check if the user already exists
    if id "$username" &>/dev/null; then
        echo "User $username already exists. Skipping user creation."
        return 0
    fi

    # Creating user with home directory
    if ! sudo useradd -m -d /home/"$username" -s /bin/bash  -G "$3" "$username"; then
        echo "Failed to create user $username. Exiting ..."
        return 1
    fi

    # Setting user password
    if ! echo "$username":"$password" | sudo chpasswd; then
        echo "Failed to set password for user $username. Exiting ..."
        return 1
    fi

    # Force user to change password on first login
    if ! sudo chage -d 0 "$username"; then
        echo "Failed to force password change for user $username. Exiting ..."
        return 1
    fi

    echo "User $username created successfully. Please change the password on first login."
    return 0
}