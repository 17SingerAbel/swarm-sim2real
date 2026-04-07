# MCMF V46 Q&A

## 1. `buildAssignmentCostMatrixForCallingTargets` 是否对应算法中构建 sensor 和 target 之间 edge 的 cost？

是的，`buildAssignmentCostMatrixForCallingTargets(...)` 的作用就是构建 MCMF 里 “sensor -> target/target slot” 这层边的 cost。

它输出的 `assignment_cost_matrix(i, j)` 表示第 `i` 个候选 sensor 分配给第 `j` 个 calling target 的代价。

真正的 flow graph 还会在 `solveInterceptorAssignmentMCMF.m` 里把 target 展开成 slot。比如每个 target 需要 2 个 interceptor，就会变成 2 个 target slots。

换句话说：

- `buildAssignmentCostMatrixForCallingTargets(...)` 负责 simulation 语义下的 cost matrix。
- `solveInterceptorAssignmentMCMF(...)` 负责把这个 cost matrix 转成 min-cost max-flow 图。

## 2. 为什么 `interceptor_process_state{other_tid}` 会被设置成 `NONE`？

在 `example_V46_Yeqi.m` 的 `PENDING_SELECTION` 逻辑里，如果多个 target 同时处于 `PENDING_SELECTION`，我们会把它们合并成一个 global assignment 一次性解决。

例如 target 1 和 target 2 同时需要 interceptor，代码在处理 target 1 的 selection 时，会把 `[1; 2]` 一起送进 MCMF。此时两个 target 的 sensor 都已经分配完成了，所以 target 2 不能在下一轮再进入 `PENDING_SELECTION` 重复分配一次。

如果不把 `other_tid` 对应的 process state 设回 `NONE`，就可能出现重复抢 sensor 或覆盖刚才 assignment 的问题。

这里设成 `NONE` 的含义是：这个 target 的本轮 handover request 已经在 global MCMF batch 中处理完了。

## 3. `test_interceptor_assignment.m` 是否通过了？

是的，测试文件通过了。

运行命令是：

```powershell
matlab.exe -batch "cd('C:/Users/abel/Desktop/MIE8888/mie8888'); results = runtests('test_interceptor_assignment.m'); assertSuccess(results);"
```

输出显示：

```text
Running test_interceptor_assignment
....
Done test_interceptor_assignment
```

这表示 `test_interceptor_assignment.m` 中的 4 个 unit test 都通过了。
