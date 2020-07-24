// An implementation not concerned with efficiency. Push in O(N), Peek and Pop in O(1).
// Contents are required to declare 'compareTo', which returns a scalar.
global simplePriorityQueue is {
	local result is lexicon().
	set result:contents to list(). // Largest-to-smallest
	set result:push to {
		parameter item.
		local i is 0.
		until i>=result:contents:length or result:contents[i]:compareTo(item)<0 {
			set i to i+1.
		}
		result:contents:insert(i, item).
	}.
	set result:peek to {
		return result:contents[result:contents:length-1].
	}.
	set result:pop to {
		local ret is result:peek().
		result:contents:remove(result:contents:length-1).
		return ret.
	}.
	return result.
}.