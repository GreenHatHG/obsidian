# Cache Memories

- Cache memories are small, fast SRAM-based memories managed automatically in hardware
  - Hold frequently accessed blocks of main memory
- CPU looks first for data in cache

![cache-memories](12-Cache-Memories/2022-04-22_221529.png)

## General Cache Organization (S,E,B)

![organization](12-Cache-Memories/2022-04-22_221928.png)

- 可以把Cache Memory的组织形式看成是一个二维数组
- valid bit指示着这些数据block是否有实际意义

## Cache Read

当程序执行一条引用内存中某个数据的指令时，CPU 将该地址发送到缓存（cache），并要求缓存返回该地址处的数据，Cache拿到地址后，定位方式如下：

![png](12-Cache-Memories/2022-04-22_222707.png)

1. 定位set：从地址中提取set index找到特定set
2. 检查tag：查看set中所有line的tag，找到与地址中tag一样的tag，并检查是否有效，这样就对应到了具体某个line
3. 使用block offset定位数据从line中第几个block开始读，直到末尾

### Example: Direct Mapped Cache(E=1)

直接映射缓存（Direct Mapped Cache）

![png](12-Cache-Memories/2022-04-22_234551.png)

定位到第1个set后（index从0开始）

![png](12-Cache-Memories/2022-04-22_234848.png)

tag不匹配的话，旧的line将被新的line覆盖，并且tag也要更新

### Direct Mapped Cache原理

假设内存系统由16个字节组成，地址4位，切分出每个block包含2个字节，缓存由4个set组成，每个set一个block。执行下面的5个指令内存最终形态：

![png](12-Cache-Memories/2022-04-22_235733.png)

变化的过程：

1. 刚开始处于默认的情况

    |     | v | Tag | Block |
    | :--: | :--: | :---: | :--: |
    |  **Set 0**  | 0 |  ?  | ? |
    | **Set 1** |      |       |  |
    | **Set 2** |      |       |  |
    | **Set 3** |      |       |  |

2. 接收到set index=0的指令，无效，所以miss。然后从内存中获取该block放到缓存中。`M[0-1]`代表从内存0~1字节处加载数据

    |     | v | Tag | Block |
    | :--: | :--: | :---: | :--: |
    |  **Set 0**  | 1 |  0  | M[0-1] |
    | **Set 1** |      |       |  |
    | **Set 2** |      |       |  |
    | **Set 3** |      |       |  |

3. 接收到set index=0，tag=0的指令，有效，hit

4. 接收到set index=3（二进制为11），同样miss并从内存中拿数据

    |     | v | Tag | Block |
    | :--: | :--: | :---: | :--: |
    |  **Set 0**  | 1 |  0  | M[0-1] |
    | **Set 1** |      |       |  |
    | **Set 2** |      |       |  |
    | **Set 3** | 1 | 0 | M[6-7] |

5. 接收set index=0，tag=1的指令，但是set 0被`tag=0 block M[0-1]`占据了，所以是miss，然后从内存中拿数据覆盖

    |     | v | Tag | Block |
    | :--: | :--: | :---: | :--: |
    |  **Set 0**  | 1 |  1  | M[8-9] |
    | **Set 1** |      |       |  |
    | **Set 2** |      |       |  |
    | **Set 3** | 1 | 0 | M[6-7] |

6. 同样set index=0，又miss不得不替换，唯一原因是每个set只有一个line。

    |     | v | Tag | Block |
    | :--: | :--: | :---: | :--: |
    |  **Set 0**  | 1 |  0  | M[0-1] |
    | **Set 1** |      |       |  |
    | **Set 2** |      |       |  |
    | **Set 3** | 1 | 0 | M[6-7] |

