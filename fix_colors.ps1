# PowerShell script to fix hardcoded colors in Flutter screens
$files = Get-ChildItem -Path "lib\screens" -Recurse -Filter "*.dart"

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    
    # Skip if file is empty
    if (-not $content) { continue }
    
    # Replace common AppBar color patterns
    $content = $content -replace 'backgroundColor: Colors\.green\[700\]', 'backgroundColor: Theme.of(context).colorScheme.primary'
    $content = $content -replace 'foregroundColor: Colors\.white', 'foregroundColor: Theme.of(context).colorScheme.onPrimary'
    
    # Replace SnackBar colors
    $content = $content -replace 'backgroundColor: Colors\.green,', 'backgroundColor: Theme.of(context).colorScheme.secondary,'
    $content = $content -replace 'backgroundColor: Colors\.red,', 'backgroundColor: Theme.of(context).colorScheme.error,'
    $content = $content -replace 'backgroundColor: Colors\.red\[700\]', 'backgroundColor: Theme.of(context).colorScheme.error'
    
    # Replace button colors
    $content = $content -replace 'color: Colors\.green\[700\]', 'color: Theme.of(context).colorScheme.primary'
    $content = $content -replace 'backgroundColor: Colors\.green\[700\]', 'backgroundColor: Theme.of(context).colorScheme.primary'
    
    # Replace common container background colors
    $content = $content -replace 'color: Colors\.green\[100\]', 'color: Theme.of(context).colorScheme.primaryContainer'
    $content = $content -replace 'backgroundColor: Colors\.green\[100\]', 'backgroundColor: Theme.of(context).colorScheme.primaryContainer'
    
    # Write back to file
    Set-Content -Path $file.FullName -Value $content -NoNewline
    Write-Host "Updated: $($file.Name)"
}

Write-Host "Color fixing complete!"
