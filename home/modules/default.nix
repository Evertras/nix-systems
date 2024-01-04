{ ... }:

{
  imports = [
    # Strictly necessary settings
    ./core

    # These are all controlled by enable flags
    ./desktop
    ./shell
  ];
}
