// TEST ONLY: deliberate bug to verify claude-review posts a comment.
// Throwaway file for end-to-end verification of the pull-requests: write
// permission fix; will be deleted without merging once claude-review
// confirms it flags this.
func maxOfTwo(_ a: Int, _ b: Int) -> Int {
    return a < b ? a : b
}
