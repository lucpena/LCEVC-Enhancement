#!/bin/bash

echo "Syncing files with GitHub..."

echo -e "\npull"
echo "-------------------"
git pull

echo -e "\nadd"
echo "-------------------"
if git add .; then
    echo "OK"
else
    echo "FAIL"
    exit 1
fi

echo -e "\ncommit"
echo "-------------------"
git commit -m "Updated via sync.sh"

echo -e "\npush"
echo "-------------------"
git push

echo -e "\n\n > Files synced with GitHub.\n"

read -p "Press Enter to exit..."