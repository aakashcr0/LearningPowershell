# Set current and previous dates
$today = Get-Date
$today1 = $today.AddDays(-1).ToString("yyyy/MM/dd")
$today = $today.AddDays(-1).ToString("dd/MM/yyyy")
Write-Host $today1
Clear-Content 'D:\Automation\MonthFC\filename.txt'
Clear-Content 'D:\Automation\Filecount\FC.csv'
Clear-Content 'D:\Automation\MonthFC\bc.txt'
Clear-Content 'D:\Automation\MonthFC\ip.txt'
Clear-Content 'D:\Automation\MonthFC\LFReserve.txt'
Clear-Content 'D:\Automation\MonthFC\CSReserve.txt'

# Set SQL path and query paths - queries are basically preset queries with the final part of it missing which will be added on later in the script
cd 'C:\Program Files\MySQL\MySQL Server 5.7\bin'
$query = 'D:\Automation\FileCount\Query.txt'
$ceq   = 'D:\Automation\FileCount\CSquery.txt'

# IPs and codes of all locations - haven't implemented a json file here yet so storing the locations and ips correspondingly in arrays
$ips = @(
  	# Enter IPS here
)

$code = @(
 	# Enter Location names here
)

$cip = $ips[0]
$cbc = $code[0]
$c   = ""
$n   = 0

# Adding CSV file header to the final csv
"Location" + ',' + "Local File Count" + ',' + "CS File Count" + ',' + "Match(True/False)" + ',' + "Date" | Add-Content "D:\Automation\Filecount\FC.csv"

# Loop through each IP/location
for ($i = 0; $i -lt $ips.Length; $i++) {
    $qcontent = Get-Content $query -Raw
    $qq       = Get-Content $ceq -Raw
    $cip      = $ips[$i]
    $cbc      = $code[$i]
    $n1       = 0
    $n2       = 0

    # Fetch location data where query returns the count(filename) for each location by using the ips in the array
    try {
        $c  = .\mysql.exe -h "$cip" -P 3306 -u root -p '*****' -e "$qcontent"
        $n1 = $c | Select-String -Pattern '^\d+$' | ForEach-Object { $_.Line }
    }
    catch {
        "Could not connect to $cbc" | Add-Content 'D:\Automation\Filecount\FC.csv'
    }

    # This part is in the central server where i need to use the location code to find the file count of that particular location
    $c  = .\mysql.exe -u root -p '*****' -e "$qq"
    $n2 = $c | Select-String -Pattern '^\d+$' | ForEach-Object { $_.Line }

    # If file count of location matches the central server, it adds true, else it adds false to that location in the csv
    if ($n1 -eq $n2) {
        "$cbc" + ',' + "$n1" + ',' + "$n2" + ',' + "True" + ',' + "$today" |
            Add-Content "D:\Automation\Filecount\FC.csv"
    }
    else {
        "$cbc" + ',' + "$n1" + ',' + "$n2" + ',' + "False" + ',' + "$today" |
            Add-Content "D:\Automation\Filecount\FC.csv"
        Add-Content $cbc -Path "D:\Automation\MonthFC\bc.txt"
        Add-Content $cip -Path "D:\Automation\MonthFC\ip.txt"
    }
}

# Resetting the query - This part wouldn't be necessary if I used a json so yeah, I was lazy 
$x = Get-Content "D:\Automation\Filecount\CSquery.txt"
$x = $x -replace '--first ip in list--', '--last ip in list--'
Set-Content -Path $ceq -Value $x


############## This is the part where I had the SMTP object to send the csv file ##############


# The unique value for each file in the db was called a reserve so using that code to find the missing files by comparing central servers & locations reserve values of that day
$lrq = ""
$crq = ""
$i   = 0

# These files have the IP and the location code where there is a file count mismatch
$mip = @(Get-Content 'D:\Automation\MonthFC\ip.txt')
$mbc = @(Get-Content 'D:\Automation\MonthFC\bc.txt')


$lrq = "select Reserve5 from dbname where (calldate = '" + $today1 + " 00:00:00') and (branchcode = '" + $mbc[$i] + "');"
$crq = "select Reserve5 from dbname where (calldate = '" + $today1 + " 00:00:00') and (branchcode = '" + $mbc[$i] + "');"

# Exporting reserve list
for ($i = 0; $i -lt $mip.Count; $i++) {
    $crq = "select Reserve5 from dbname where (calldate = '" + $today1 + " 00:00:00') and (branchcode = '" + $mbc[$i] + "');"
    $cc  = $mbc[$i]
    $c = .\mysql.exe -h $mip[$i] -P 3306 -u root -p '*****' -e "$lrq"
    $c | Add-Content 'D:\Automation\MonthFC\LFReserve.txt'
    Write-Host $c.Count
    $c = .\mysql.exe -u root -p '*****' -e "$crq" -N
    $c | Add-Content 'D:\Automation\MonthFC\CSReserve.txt'
    Write-Host $c.Count

    # Compare local and central reserve values
    $lfr    = Get-Content 'D:\Automation\MonthFC\LFReserve.txt'
    $cfr    = Get-Content 'D:\Automation\MonthFC\CSReserve.txt'
    $missing = $lfr | Where-Object { $_ -notin $cfr }

    Set-Content 'D:\Automation\MonthFC\missing.txt' $missing

    # Lookup each missing reserve
    $missing | ForEach-Object {
    	$current = $_
    	Write-Host $current

    	$lmf = "select filename from dbname where reserve5 = '" + $current + "';"
    	Write-Host $lmf

    	$c = .\mysql.exe -h $mip[$i] -P 3306 -u root -p '*****' -e "$lmf"
    	"$c" + ',' + "$cc" | Add-Content "D:\Automation\MonthFC\filename.txt"
}

    Clear-Content 'D:\Automation\MonthFC\LFReserve.txt'
    Clear-Content 'D:\Automation\MonthFC\CSReserve.txt'
}


############## This part is where I had the SMTP object to send the missing file txt aftter checking if its empty or not  ##############

