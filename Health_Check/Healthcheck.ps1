# Setting path for SQL
cd # Enter the MySQL path for execution

# Extracting details from JSON and getting today's date
$json = Get-Content -Raw -Path 'json/file/path' | ConvertFrom-Json
$tday = (Get-Date).ToString("yyyy/MM/dd") + " 00:00:00"
Write-Host $tday

# Preparing SQL query
$query = "SELECT callerid FROM dbname WHERE ((calldate = '$tday') AND (branchcode = '"
Clear-Content 'D:\Automation\NewHealthCheck\hc.csv'

foreach ($location in $json) {
    $code = $location.code
    $ip = $location.ip
    $query += $code + "')); "
}

# Getting all available test call extensions
$cid = .\mysql.exe -u root -p"insertpasswordhere" -D databasename -e "$query" -N
$TrueList = @()

# Looping through each PRI in JSON
foreach ($location in $json) {
    foreach ($pri in $location.PRI.PSObject.Properties) {
        $priNum = [int]$pri.Name
        $priNumStr = $pri.Name

        if ($TrueList -contains $priNum) {
            continue
        }

        foreach ($cn in $cid) {
            $value = $cn - $priNum
            if (($value -lt 300) -and ($value -ge 0)) {
                $qqq = "SELECT filename FROM dbname WHERE (callerid = '$cn' AND branchcode = '$($location.code)' AND calldate = '$tday') LIMIT 1;"
                Write-Host $qqq
                $fn = .\mysql.exe -u root -p"insertpasswordhere" -D databasename -e "$qqq" -N
                $pri.Value = $fn
                $TrueList += $priNum
                break
            }
        }
    }
}


# Checking 1600 PRI
$deldp2 = .\mysql.exe -u root -p"insertpasswordhere" -D databasename -e "SELECT filename FROM dbname WHERE (branchcode = 'DELDP2' AND calldate = '$tday') LIMIT 1;" -N
$andhr = .\mysql.exe -u root -p"insertpasswordhere" -D databasename -e "SELECT filename FROM dbname WHERE (branchcode = 'ANDHR2' AND calldate = '$tday') LIMIT 1;" -N
$andhr = [string]$andhr
$deldp2 = [string]$deldp2

Write-Host $andhr

foreach ($location in $json) {
    if ($location.code -eq "ANDHR2") {
        if (-not [string]::IsNullOrEmpty($andhr)) {
            $location.PRI."1600" = $andhr
        }
    } elseif ($location.code -eq "DELDP2") {
        if (-not [string]::IsNullOrEmpty($deldp2)) {
            $location.PRI."1600" = $deldp2
        }
    }
}

# Checking with extensions for all the false values
$query = "SELECT extension FROM dbname WHERE ((calldate = '$tday') AND (branchcode = '"
Write-Host $query

foreach ($location in $json) {
    $code = $location.code
    $ip = $location.ip
    $query1 = $query + $code + "')) ;"
    Write-Host $query1

    $TrueList = @()
    foreach ($pri in $location.PRI.PSObject.Properties) {
        $pval = [string]$pri.Value
        $priNum = [int]$pri.Name
        Write-Host $pval

        if ($pval -eq "False") {
            if ($TrueList -contains $priNum) {
                continue
            }

            $val = [int]$pri.Name
            $cid = .\mysql.exe -u root -p"insertpasswordhere" -D databasename -e "$query1" -N
            Write-Host $cid

            foreach ($cn in $cid) {
                $value = $cn - $val
                if (($value -lt 300) -and ($value -ge 0)) {
                    $qqq = "SELECT filename FROM dbname WHERE (extension = '$cn' AND branchcode = '$code' AND calldate = '$tday') LIMIT 1;"
                    Write-Host $qqq
                    $fn = .\mysql.exe -u root -p"insertpasswordhere" -D databasename -e "$qqq" -N
                    Write-Host $fn
                    $pri.Value = $fn
                    $TrueList += $val
                    break
                }
            }
        }
    }
}

# Save result JSON
$json | ConvertTo-Json -Depth 10 | Set-Content -Path 'D:\Automation\NewHealthCheck\result.json'

# Displaying the result in CSV
'"Location", "PRI#", "PRINumber", "PRI Call Status", "Filename"' | Add-Content 'D:\Automation\NewHealthCheck\hc.csv'

foreach ($location in $json) {
    $code = $location.code
    $i = 1
    foreach ($pri in $location.PRI.PSObject.Properties) {
        $cuv = [string]$pri.Value
        if ($cuv -eq "false") {
            '"'+$code+'", "PRI '+$i+'", "'+$pri.Name+'", "FALSE", "No calls"' | Add-Content  'D\Automation\NewHealthCheck\hc.csv'
        } else {
            $num = [int]$pri.Name
            '"'+$code+'", "PRI '+$i+'", "'+$pri.Name+'", "TRUE", "'+$pri.Value+'"' | Add-Content 'D:\Automation\NewHealthCheck\hc.csv'
        }
        $i = $i + 1
    }
}


#### This is where I made an object for SMTP to send the CSV file to the team ####

