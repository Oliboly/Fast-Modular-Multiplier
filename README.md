# Fast-Modular-Multiplier
A 12-bit pipelined modular multiplier based on Barrett reduction algorithm.
基于Barrett约减算法的12位流水线模乘器
## 模块名称: mod_multiplier
### 功能描述: 
- 基于巴雷特约减法的12位流水线快速模乘器，支持在固定周期内计算 (a*b) mod q（q=3329）
### 关键设计:
- 使用5级流水线结构，每阶段由counter控制
- 采用巴雷特约减法优化模运算（避免除法）
- 输入使能后，经过5个周期输出稳定结果
