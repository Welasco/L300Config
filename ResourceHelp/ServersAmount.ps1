function serversamount{
    param(
        [Int]$StudantsAmoun
    )
    #$StudantsAmoun = 4
    $div = 4

    if($StudantsAmoun/$div -eq 0){
        Write-Output "At least one App Service Plan is needed: " $StudantsAmoun+1
    }
    if($StudantsAmoun/$div -ne 0){
        if($StudantsAmoun%$div -gt 0){
            Write-Output "Mod greater then 0 increasing App Service plan: " ([math]::Truncate(($StudantsAmoun/$div)+1))
        }
        if($StudantsAmoun%$div -eq 0){
            Write-Output "Getting the result of div perfect division: " ($StudantsAmoun/$div)
        }
    }
}