describe 'Get-IsPowerOfTwo' {
    it 'returns true for powers of 2' {
        Get-IsPowerOfTwo -Num 32768 | Should be $true
    }
    it 'returns false for non-powers of 2' {
        Get-IsPowerOfTwo -Num 6 | Should be $false
    }
}
