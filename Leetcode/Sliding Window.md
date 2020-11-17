### Sliding Window

#### 3. Longest Substring Without Repeating Characters

Given a string s, find the length of the longest substring without repeating characters.

```java
public int lengthOfLongestSubstring(String s) {
        int[] c = new int[256];
        int l = 0, r = -1;
        int res = 0;
        while (l<s.length()) {
            if (r+1<s.length() && c[s.charAt(r+1)] == 0) {
                r += 1;
                c[s.charAt(r)] = 1;
            } else {
                c[s.charAt(l)] = 0;
                l += 1;
            }
            if (res < r-l+1) {
                res = r-l+1;
            }
        }
        return res;
    }
```

#### 239. Sliding Window Maximum

```java
public int[] maxSlidingWindow(int[] nums, int k) {
        int[] res = new int[nums.length-k+1];
        int i;
        Deque<Integer> deq = new LinkedList<>();
        for (i=0; i<nums.length; i++) {
            while(!deq.isEmpty() && nums[deq.getLast()]<nums[i]) 			{
                deq.removeLast();
            }
            deq.addLast(i);
            if (i-deq.getFirst() > k-1) {
                deq.removeFirst();
            }
            if (i>=k-1) {
                res[i-k+1] = nums[deq.getFirst()];
            }
        }
        return res;
    }
```

#### 219



#### 209