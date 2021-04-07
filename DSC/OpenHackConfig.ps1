$packages = @(
   #   @{Name = 'wsl2'; Param = '/Retry:true' }
   #@{Name = 'wsl-ubuntu-2004' } #; Depends = "wsl2"
   #@{Name = 'docker-desktop' } #; Depends = "wsl2"
   @{Name = 'azure-cli' }
   @{Name = 'azcopy10' }
   @{Name = "powershell-core" }
   @{Name = 'vscode' }
   @{Name = 'kubernetes-cli' }
   @{Name = 'kubernetes-helm' }
   @{Name = 'git' }
   @{Name = 'cascadiacode' }
   @{Name = 'cascadiacodepl' }
   @{Name = 'microsoft-windows-terminal' }
   @{Name = 'sysinternals' }
   @{Name = 'istioctl' }
   @{Name = 'azure-data-studio' }
)

$vscodeextensions = @(
'docsmsft.docs-yaml'
'ms-dotnettools.vscode-dotnet-runtime'
'ms-kubernetes-tools.vscode-aks-tools'
'ms-kubernetes-tools.vscode-kubernetes-tools'
'ms-vscode-remote.remote-containers'
'ms-vscode-remote.remote-wsl'
'ms-vscode.powershell'
'ms-vscode.vscode-node-azure-pack'
'msazurermtools.azurerm-vscode-tools'
'redhat.vscode-yaml'
)

Configuration OpenHackConfig
{
   param(
      [Parameter(Mandatory = $true)]
      [ValidateNotNullorEmpty()]
      [PSCredential]
      $RunAsCredential,
      [string]$TimeZoneId='Romance Standard Time'
   )

   Import-DscResource -ModuleName PSDscResources
   Import-DscResource -ModuleName cChoco
   Import-DscResource -ModuleName PowerShellModule
   Import-DscResource -ModuleName vscode
   Import-DscResource -ModuleName ComputerManagementDsc

   Node "localhost"
   {
      LocalConfigurationManager {
         DebugMode          = 'ForceModuleImport'
         RebootNodeIfNeeded = $true
      }

      WindowsOptionalFeature WindowsSubsystemLinux {
         Name   = 'Microsoft-Windows-Subsystem-Linux'
         Ensure = 'Present'
      }

      WindowsOptionalFeature VirtualMachinePlatform {
         Name      = 'VirtualMachinePlatform'
         Ensure    = 'Present'
         DependsOn = '[WindowsOptionalFeature]WindowsSubsystemLinux'
      }

      MsiPackage WSL2Update {
         ProductId = '{8D646799-DB00-4000-AE7A-756A05A4F1D8}'
         Path      = 'https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi'
         Ensure    = 'Present'
         DependsOn = "[WindowsOptionalFeature]VirtualMachinePlatform"
      }

      Registry WSL2Default {
         Key                  = 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss'
         Ensure               = 'Present'
         ValueName            = 'DefaultVersion'
         ValueData            = '2'
         ValueType            = 'Dword'
         Force                = $true
         PsDscRunAsCredential = $RunAsCredential
         DependsOn            = '[MsiPackage]WSL2Update'
      }

      cChocoInstaller installChoco {
         InstallDir           = 'c:\choco'
         PsDscRunAsCredential = $RunAsCredential
         DependsOn            = "[MsiPackage]WSL2Update"
      }
      
      cChocoFeature allowGlobalConfirmation {

         FeatureName          = 'allowGlobalConfirmation'
         Ensure               = 'Present'
         DependsOn            = '[cChocoInstaller]installChoco'
         PsDscRunAsCredential = $RunAsCredential
      }
      
      foreach ($package in $packages) {
         $depends = @('[cChocoInstaller]installChoco')
         if (![String]::IsNullorEmpty($package.Depends)) { 
            $depends += $package.Depends.split(',') | ForEach-Object { "[cChocoPackageInstaller]install$_" }
         }
      
         cChocoPackageInstaller "install$($package.Name)" {
            Name                 = $package.Name
            DependsOn            = $depends
            Params               = $packages.Param
            AutoUpgrade          = $True
            PsDscRunAsCredential = $RunAsCredential
         }
      }

      cChocoPackageInstaller 'installwsl-ubuntu-2004' {
         Name                 = 'wsl-ubuntu-2004'
         DependsOn            = @('[cChocoInstaller]installChoco', '[Registry]WSL2Default' )
         AutoUpgrade          = $True
         PsDscRunAsCredential = $RunAsCredential
      }

      cChocoPackageInstaller 'installdocker-desktop' {
         Name                 = 'docker-desktop'
         DependsOn            = @('[cChocoInstaller]installChoco', '[Registry]WSL2Default' )
         AutoUpgrade          = $True
         PsDscRunAsCredential = $RunAsCredential
      }

      PSModuleResource Az {
         Ensure      = 'Present'
         Module_Name = 'Az'
         DependsOn   = '[cChocoInstaller]installChoco'
      }

      PSModuleResource AzureAD {
         Ensure      = 'Present'
         Module_Name = 'AzureAD'
         DependsOn   = '[cChocoInstaller]installChoco'
      }

      foreach ($extension in $vscodeextensions) {
         VSCodeExtension "PSExt-$extension" {
            Name = $extension
            Ensure = 'Present'
            PsDscRunAsCredential = $RunAsCredential
            DependsOn = '[cChocoPackageInstaller]installvscode'
        }
      }

      TimeZone TimeZone
        {
            IsSingleInstance = 'Yes'
            TimeZone         = $TimeZoneId
        }
      

   }
}

#OpenHackConfig

#Start-DscConfiguration .\OpenHackConfig -wait -Verbose -Force
