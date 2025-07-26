{ config, pkgs, lib, ... }:
{
  # Modern office applications - secure by default
  environment.systemPackages = with pkgs; [
    # Office suites
    libreoffice-fresh    # Full-featured office suite
    onlyoffice-bin       # Modern MS Office-compatible suite
    
    # Document viewers/editors
    evince              # PDF viewer (GNOME default)
    okular              # Feature-rich PDF viewer (KDE)
    
    # Additional document tools
    pandoc              # Universal document converter
    texlive.combined.scheme-medium  # LaTeX support for advanced documents
  ];

  # File associations for office documents
  xdg.mime.defaultApplications = {
    # LibreOffice as primary
    "application/vnd.oasis.opendocument.text" = "libreoffice-writer.desktop";
    "application/vnd.oasis.opendocument.spreadsheet" = "libreoffice-calc.desktop";
    "application/vnd.oasis.opendocument.presentation" = "libreoffice-impress.desktop";
    
    # OnlyOffice for MS Office formats
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "onlyoffice-desktopeditors.desktop";
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "onlyoffice-desktopeditors.desktop";
    "application/vnd.openxmlformats-officedocument.presentationml.presentation" = "onlyoffice-desktopeditors.desktop";
    
    # Legacy MS Office formats
    "application/msword" = "onlyoffice-desktopeditors.desktop";
    "application/vnd.ms-excel" = "onlyoffice-desktopeditors.desktop";
    "application/vnd.ms-powerpoint" = "onlyoffice-desktopeditors.desktop";
    
    # PDF documents
    "application/pdf" = "evince.desktop";
  };

  # Optional: Disable telemetry for LibreOffice (though minimal)
  environment.variables = {
    # LibreOffice privacy settings
    LO_JAVA_JFR = "false";  # Disable Java Flight Recorder
  };
}
