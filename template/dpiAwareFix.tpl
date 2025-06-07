#TEMPLATE(DPIAwareFixTpl, 'Fix DPI Aware in the manifest'), FAMILY('ABC'), FAMILY('CW20')
#! --------------------------------------------------------------------------
#EXTENSION(gxDPIAwareFix, 'Activate DPI Aware fix'), APPLICATION, DESCRIPTION('Activate DPI Aware fix')
#DISPLAY('')
#SHEET
  #TAB('Global settings')
    #ENABLE(%ProgramExtension = 'EXE'),CLEAR
      #PROMPT('Generate new or modify existing manifest', CHECK),%gGenerateManifest,DEFAULT(1),AT(10)
      #ENABLE(%gGenerateManifest)
        #PROMPT('Default DPI awareness mode:', DROP('System aware[System]|Per Monitor[PerMonitorV2]')),%gDPIAwarenessMode,DEFAULT('PerMonitorV2')
        #PROMPT('Link manifest as a resource', CHECK),%gLinkManifest,DEFAULT(1),AT(10)
      #ENDENABLE
    #ENDENABLE
    #DISPLAY
    #PROMPT('Completely disable this template',CHECK),%gDisable,DEFAULT(0),AT(10)
  #ENDTAB
  #TAB('About')
    #BOXED('')
      #DISPLAY('DPI Aware fix')
      #DISPLAY('Mike Duglas')
      #DISPLAY('Copyright © 2021 All Rights Reserved')
    #ENDBOXED
  #ENDTAB
#ENDSHEET
#! --------------------------------------------------------------------------
#AT(%AfterGeneratedApplication),WHERE(NOT %gDisable)
  #IF(%gGenerateManifest)
    #CALL(%DpiAwareEnableManifest, %gLinkManifest, %gDPIAwarenessMode)
  #ENDIF
#ENDAT
#! --------------------------------------------------------------------------
#GROUP(%DpiAwareCreateManifest, %pManifestFile, %pDPIMode),AUTO
  #CREATE(%pManifestFile)
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0" xmlns:asmv3="urn:schemas-microsoft-com:asm.v3">
  <assemblyIdentity
    version="1.0.0.0"
    processorArchitecture="X86"
    name="SoftVelocity.Clarion%CWVersion.Application"
    type="win32"
  />
  <description>%Application</description>
  #CALL(%DpiAwareInsert, %pDPIMode)
</assembly>
  #CLOSE(%pManifestFile)
#! --------------------------------------------------------------------------
#GROUP(%DpiAwareFixManifest, %pManifestFile, %pDPIMode),AUTO
  #DECLARE(%FileLine)
  #DECLARE(%asmv3Found, LONG)
  #DECLARE(%TmpFile)
  #SET(%TmpFile, %ManifestFile &'.$$$')
  #OPEN(%pManifestFile),READ
  #CREATE(%TmpFile)
  #LOOP
    #READ(%FileLine)
    #IF(%FileLine = %EOF)
      #BREAK
    #ENDIF
    #IF(INSTRING('<assembly ',%FileLine,1,1) > 0)
      #IF(INSTRING('xmlns:asmv3=',%FileLine,1,1) = 0)
        #! fix missing xmlns:asmv3 attribute bug
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0" xmlns:asmv3="urn:schemas-microsoft-com:asm.v3">
      #ELSE
%FileLine
      #ENDIF
    #ELSIF(INSTRING('<asmv3:application',%FileLine,1,1) > 0)
      #! no output from <asmv3:application> to </asmv3:application>
      #SET(%asmv3Found, %True)
    #ELSIF(INSTRING('</asmv3:application',%FileLine,1,1) > 0)
      #SET(%asmv3Found, %False)
    #ELSIF(INSTRING('<</assembly>',%FileLine,1,1) > 0)
      #! output dpiAwareness prior to closing </assembly> tag
      #CALL(%DpiAwareInsert, %pDPIMode)
%FileLine
    #ELSE
      #IF(%asmv3Found=%False)
%FileLine
      #ENDIF
    #ENDIF
  #ENDLOOP
  #CLOSE(%pManifestFile),READ
  #CLOSE(%TmpFile)
  #REPLACE(%pManifestFile,%TmpFile)
  #REMOVE(%TmpFile)
#! --------------------------------------------------------------------------
#GROUP(%DpiAwareInsert, %pDPIMode),AUTO
  <asmv3:application>
    <asmv3:windowsSettings>
    #CASE(%pDPIMode)
    #OF('PerMonitorV2')
      <dpiAware xmlns="http://schemas.microsoft.com/SMI/2005/WindowsSettings">True/PM</dpiAware>
      <dpiAwareness xmlns="http://schemas.microsoft.com/SMI/2016/WindowsSettings">PerMonitorV2</dpiAwareness>
    #OF('System')
      <dpiAware xmlns="http://schemas.microsoft.com/SMI/2005/WindowsSettings">True</dpiAware>
    #ENDCASE
    </asmv3:windowsSettings>
  </asmv3:application>
#! --------------------------------------------------------------------------
#GROUP(%DpiAwareEnableManifest, %pLinkManifest, %pDPIMode),AUTO
  #DECLARE(%ManifestFile)
  #SET(%ManifestFile, %ProjectTarget & '.manifest')
  #IF(NOT FILEEXISTS(%ManifestFile))
    #! create manifest if not exists
    #CALL(%DpiAwareCreateManifest, %ManifestFile, %pDPIMode)
  #ELSE
    #! fix manifest
    #CALL(%DpiAwareFixManifest, %ManifestFile, %pDPIMode)
  #ENDIF
  #IF(%pLinkManifest)
    #PROJECT(%ManifestFile)
  #ENDIF
