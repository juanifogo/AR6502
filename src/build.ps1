if(!$args){
    echo "Usage: build.ps1 [-wozmon] <filename>" 
    return
}

$inFile = $args[-1]
$infileName = $inFile.Substring(1)

if([System.IO.File]::Exists("$pwd$inFileName") -eq $false || 
    $args.Contains("-help") || 
    $args.Contains("-h") ||
    $args.Contains("--h") || 
    $args.Contains("--help")
    ){
    echo "Usage: build.ps1 [-wozmon] <filename>"
    return
}

$name = $inFile.split('.')[1].Substring(1)
$outFile = ".\bin\$name.out"
vasm6502_oldstyle.exe -Fbin -dotdir -o $outFile $inFile
if($args.Contains("-wozmon")) {
    Write-Host "WARNING:" -ForegroundColor Yellow
    Write-Host "This will only work if your .asm file starts at address 0x1000. Continue? (y/n)"
    $input = Read-Host
    if($input -eq "n"){
        Write-Host "Aborting..."
        return
    }
    $hexOut = (".\wozmonInstructions\" + $name + "Wozmon.txt")
    hexdump -v -e '"1%03_ax: " 16/1 "%02X " "\n"' .\bin\$name.out | tr 'a-f' 'A-F' > $hexOut
}