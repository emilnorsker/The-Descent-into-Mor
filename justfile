# Run all Godot tests headlessly
test:
    godot -s --headless addons/gut/gut_cmdln.gd -gconfig=".gutconfig" -gexit

# Run a specific test file
test-file FILE_NAME:
    godot -s --headless addons/gut/gut_cmdln.gd -gconfig=".gutconfig" -gexit -gselect="{{FILE_NAME}}" 