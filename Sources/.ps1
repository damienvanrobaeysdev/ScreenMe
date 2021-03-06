#========================================================================
#
# Tool Name	: ScreenMe
# Author 	: Damien VAN ROBAEYS
# Date	 	: 08/11/2019
#
#========================================================================

$Script:Current_Folder = split-path $MyInvocation.MyCommand.Path
[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | out-null
[System.Reflection.Assembly]::LoadFrom("$Current_Folder\MahApps.Metro.dll")      | out-null  
[System.Reflection.Assembly]::LoadFrom("$Current_Folder\System.Windows.Interactivity.dll") | out-null
[System.Reflection.Assembly]::LoadFrom("$Current_Folder\MahApps.Metro.IconPacks.dll")      | out-null  

[System.Windows.Forms.Application]::EnableVisualStyles()

function LoadXml ($filename){
    $XamlLoader=(New-Object System.Xml.XmlDocument)
    $XamlLoader.Load($filename)
    return $XamlLoader
}

$XamlMainWindow=LoadXml("$Current_Folder\ScreenMe.xaml")
$Reader=(New-Object System.Xml.XmlNodeReader $XamlMainWindow)
$Form=[Windows.Markup.XamlReader]::Load($Reader)

$ScreeMe  = $Form.FindName("ScreeMe")
$Open_Folder  = $Form.FindName("Open_Folder")

$SystemDrive = $env:SystemDrive 

$Open_Folder.add_Click({
	If($File -ne "")
		{		
			$File_Parent = (Get-item $Get_Screenshot_Path).DirectoryName			
			If($SystemDrive -like "*X:*")
				{
					start-process powershell -argumentlist "powershell -noexit -command ""get-childitem $File_Parent"""					
				}
			ElseIf($SystemDrive -like "*C:*")
				{
					invoke-item $File_Parent		
				}				
		}
})

$Continue_Process = $False
$Stop_Capture_Process = $False
$Open_Folder.Visibility = "Collapsed"
	
		
$ScreeMe.Add_Click({
	$Form.Left = $([System.Windows.SystemParameters]::WorkArea.Width-$Form.Width) / 2
	$Form.Top = $([System.Windows.SystemParameters]::WorkArea.Height-$Form.Height) / 2

	$form.Width = "500"	
	$form.Height = "300"	
		
	$ProgData = $env:PROGRAMDATA	
	If($SystemDrive -like "*X:*")
		{
			$Script:Dest_Folder = "$SystemDrive\ScreenMe_Pictures\Screen"
			$Script:Full_Path = "$Dest_Folder\ScreenMe_Picture.jpg"
		}
	ElseIf($SystemDrive -like "*C:*")
		{
			$Script:Dest_Folder = "$ProgData\ScreenMe_Pictures"
			$Script:Full_Path = "$Dest_Folder\ScreenMe_Picture.jpg"			
		}

	$okAndCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative
	
	$Button_Style_Obj = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()
	$Button_Style_Obj.AffirmativeButtonText = "Local"
	$Button_Style_Obj.NegativeButtonText     = "Mapped drive"

	$Button_Style_Obj.DialogTitleFontSize = "16"
	$Button_Style_Obj.DialogMessageFontSize = "12"	
	
	$result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Form,"Picture path","Save the picture locally ?",$okAndCancel, $Button_Style_Obj)	
	If($result -eq "Affirmative")
		{
			$Button_Style_Obj.AffirmativeButtonText = "Copy"
			$Button_Style_Obj.NegativeButtonText = "Cancel"	
			$Button_Style_Obj.DefaultText = $Full_Path	
			$Button_Style_Obj.DefaultButtonFocus = "Affirmative"

			$Script:Get_Screenshot_Path = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($Form,"Picture path","Where do you want to save the picture ?", $Button_Style_Obj)												

			If($Get_Screenshot_Path -eq "")
				{
					$Script:Continue_Process = $False
				}
			ElseIf($Get_Screenshot_Path -eq $null)
				{
					$Script:Continue_Process = $False
				}	
			Else
				{
					$Script:Export_Type = "Local_Drive"				
					$Script:Continue_Process = $True		
					$Script:Get_Screenshot_Folder_Path = split-path $Get_Screenshot_Path	
				}
		}
	Else
		{
			$Button_Style_Obj.AffirmativeButtonText = "Continue"
			$Button_Style_Obj.NegativeButtonText     = "Cancel"		
			$Script:Get_Screenshot_Path = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($Form,"Picture path","Where do you want to save the picture ?", $Button_Style_Obj)						
								
			If($Get_Screenshot_Path -eq "")
				{
					$Script:Continue_Process = $False
				}
			ElseIf($Get_Screenshot_Path -eq $null)
				{
					$Script:Continue_Process = $False
				}	
			Else
				{
					$Script:Export_Type = "Mapped_Drive"
					$Button_Style_Obj = [MahApps.Metro.Controls.Dialogs.LoginDialogSettings]::new()
					$Button_Style_Obj.EnablePasswordPreview = $true
					$Button_Style_Obj.RememberCheckBoxText = $true
					$Button_Style_Obj.DialogTitleFontSize = "16"
					$Button_Style_Obj.DialogMessageFontSize = "12"							
					$Button_Style_Obj.AffirmativeButtonText = "Copy"
					$Button_Style_Obj.NegativeButtonText     = "Cancel"					
					$Button_Style_Obj.NegativeButtonVisibility  = "Visible"				
			
					$Login = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalLoginExternal($Form,"Credentials","Type your credentials", $Button_Style_Obj) 
					$User_Login = $Login.Username
					$User_PWD  = $Login.Password	
										
					If($Login -eq "")
						{
							$Script:Continue_Process = $False
						}
					ElseIf($Login -eq $null)
						{
							$Script:Continue_Process = $False
						}	
					Else
						{
							$Script:Continue_Process = $True			
							Try
								{
									$Secure_PWD = $User_PWD | ConvertTo-SecureString -AsPlainText -Force 
									$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User_Login, $Secure_PWD						
									New-PSDrive -name "K" -PSProvider FileSystem -Root $Get_Screenshot_Path -Persist -Credential $Creds -ea silentlycontinue -ErrorVariable PSDrive_Error	
									
									If($PSDrive_Error -ne $null)
										{
											[MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Form,"Oops :-(","Can not map the drive !!!",$okAndCancel)										
											$Script:Continue_Process = $False										
										}
									Else
										{
											$Script:Continue_Process = $True
										}	
								}
							Catch
								{
									[System.Windows.Forms.MessageBox]::Show("Oops`nCan not map the drive !!!")																				
									$Script:Continue_Process = $False
								}							
							$Script:Get_Screenshot_Folder_Path = $Get_Screenshot_Path																
							$Script:Get_Screenshot_Path = "$Get_Screenshot_Path\ScreenMe_Picture.jpg"								
						}						
				}						
		}
				
		If($Continue_Process -eq "True")
			{
				If(test-path $Get_Screenshot_Path)
					{	
						$Button_Style_Obj.AffirmativeButtonText = "Copy"
						$Button_Style_Obj.NegativeButtonText = "Cancel"	
						$Button_Style_Obj.DefaultText = ''	
						$Button_Style_Obj.DefaultButtonFocus = "Affirmative"

						$Script:Get_New_Name = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($Form,"Oops :-(","This file already exists. Type new JPG name", $Button_Style_Obj)												
						If($Get_New_Name -eq "")
							{
								$Script:Stop_Capture_Process = $True
							}
						ElseIf($Get_New_Name -eq $null)
							{
								$Script:Stop_Capture_Process = $True
							}	
						Else
							{
								If(($Get_New_Name -notlike "*.jpg"))
									{
										$Get_New_Name = "$Get_New_Name.jpg"
									}
								$Script:Get_Screenshot_Path = "$Get_Screenshot_Folder_Path\$Get_New_Name"								
								$Script:Stop_Capture_Process = $False	
							}								
					}						

				If($Script:Export_Type -eq "Local_Drive")	
					{
						$Script:Export_Folder_Path = split-path $Get_Screenshot_Path	
						If(!(test-path $Export_Folder_Path))
							{
								Try
									{					
										new-item $Export_Folder_Path -Type Directory -Force -ea stop
									}
								catch 
									{
										[System.Windows.Forms.MessageBox]::Show("Oops`nCan not create the file !!!")												
										$Script:Stop_Capture_Process = $True
									}						
							}
					}
					
				If($Stop_Capture_Process -ne $True)
					{		
						$Form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized						
						Try
							{								
								sleep 1

								Add-Type -AssemblyName System.Windows.Forms
								Add-type -AssemblyName System.Drawing
								$Screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
								$Width = $Screen.Width
								$Height = $Screen.Height
								$Left = $Screen.Left
								$Top = $Screen.Top
								$bitmap = New-Object System.Drawing.Bitmap $Width, $Height
								$graphic = [System.Drawing.Graphics]::FromImage($bitmap)
								$graphic.CopyFromScreen($Left, $Top, 0, 0, $bitmap.Size)
								$bitmap.Save($Get_Screenshot_Path) 		
																				
								$form.Width = "200"		
								$Form.WindowState = [System.Windows.Forms.FormWindowState]::Normal	
								$Open_Folder.Visibility = "Visible"
							}
						Catch
							{
								[System.Windows.Forms.MessageBox]::Show("Oops`nCan not create the file !!!")																			
								$form.Width = "200"		
								$Form.WindowState = [System.Windows.Forms.FormWindowState]::Normal	
								$Open_Folder.Visibility = "Visible"							
							}
					}
			}					

		$form.Width = "200"	
		$form.Height = "200"	
})	

$Form.ShowDialog() | Out-Null