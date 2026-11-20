# Stylized [Architecture](docs/arch.txt)

## Memory Map

| Type | Address | Description | Notes
| ---- | ------- | ----------- | -----
| `STRUCT`| `0x500` | TSS
| `QWORD[]`| `0x5e0` | PDPT
| `DWORD[]` | `0x570` | iretd block
| `QWORD`| `0x600` | TSC start
| `DWORD` | `0x608` | LFB ptr | until `initializeMemory();`
| `BYTE` | `0x60C` | RAM block count | until `initializeMemory();`
| `DWORD` | `0x608` | TID
| `DWORD[]` | `0x5000` | PD
| `DWORD[]` | `0x6000` | PT <1MB identity paging
| `STRUCT[]` | `0x20000` | Container array


## Global Functions:

| Function Name | Input | Output | Notes |
| ------------- | ----- | ------ | ----- |
| [`initializeMemory`](kernel/memory.asm) |  |  | No status
| [`kernelPageAllocate`](kernel/memory.asm) | `AL=SIZE` | `EDX=ADDR`
| [`registerContainer`](kernel/container.asm) | `EDI=PTR,AX=FLAGS,BX=HNDL` | `DX=HNDL`
| [`getRawContainer`](kernel/container.asm) | `AX=HANDLE` | `EDX=PTR`
| [`createProcedure`](kernel/procedure.asm) | `ESI=NAME,AX=CODE HNDL,BL=FLAGS` | `DX=PDHNDL`
| [`registerProcedure`](kernel/procedure.asm) | `AX=PDHNDL`
| [`giveContainer`](kernel/link.asm) | `AX=HNDL,BX=PDHNDL`
| [`mapContainer`](kernel/link.asm) | `AX=HNDL,BC=PDHNDL`
| [`startScheduler`](kernel/scheduler.asm) |  |  | Infinite
| [`initializeDriver`](driver/driver.asm) |  |  | No status

**Note**: These functions are in order of file creation, not in call order

## Structures
### HNDL:

<table>
	<tr>
		<td width="12.5%"></td>
		<td width="12.5%"></td>
		<td width="12.5%"></td>
		<td width="12.5%"></td>
		<td width="12.5%"></td>
		<td width="12.5%"></td>
		<td width="6.25%"></td>
		<td width="6.25%"></td>
		<td width="12.5%"></td>
	</tr>
	<tr>
		<th>0</th><th>1</th><th>2</th><th>3</th><th>4</th><th>5</th><th colspan="2">6</th><th>7</th>
	</tr>
	<tr>
		<td colspan="2">Flags</td>
		<td colspan="2">Owner <code>PDHNDL</code></td>
		<td colspan="3">Address</td>
		<td>Size</td>
		<td>Link Count</td>
	</tr>
</table>

#### Flags:

<table>
	<tr>
		<th>0</th><th>1</th><th>2</th><th>3</th><th>4</th><th>5</th><th>6</th><th>7</th>
	</tr>
	<tr>
		<td>R</td><td>W</td><td>C</td><td>COW</td><td>SPC</td><td>PDE</td><td>SPE</td><td>SE</td>
	</tr>
	<tr>
		<td>SR</td><td>SW</td><td>SC</td><td>SO</td><td>SPR</td><td>SPW</td><td>SPC</td><td>SPO</td>
	</tr>
</table>

| | PDE | 0 | 1
| - |------- | - | -
| SPE
| 0 |  | MDHNDL (Miscelaneous Data HaNDLe) | UDHNDL (UnDefined HaNDLe)
| 1 |  | DDHNDL (Driver Data HaNDLe) | PDHNDL (Program Data HaNDLe) |

### PDHNDL structure:

<table>
	<tr>
		<td></td>
		<td width="6.25%"></td>
		<td width="6.25%"></td>
		<td width="6.25%"></td>
		<td width="6.25%"></td>
		<td width="6.25%"></td>
		<td width="6.25%"></td>
		<td width="6.25%"></td>
		<td width="6.25%"></td>
		<td width="6.25%"></td>
		<td width="6.25%"></td>
		<td width="6.25%"></td>
		<td width="6.25%"></td>
		<td width="6.25%"></td>
		<td width="6.25%"></td>
		<td width="6.25%"></td>
		<td width="6.25%"></td>
	</tr>
	<tr>
		<th></th>
		<th>0</th><th>1</th><th>2</th><th>3</th><th>4</th><th>5</th><th>6</th><th>7</th>
		<th>8</th><th>9</th><th>A</th><th>B</th><th>C</th><th>D</th><th>E</th><th>F</th>
	</tr>
	<tr>
		<td><code>0x000</code></td>
		<td colspan="4"><code>EDI</</code>code></td>
		<td colspan="4"><code>ESI</code></td>
		<td colspan="4"><code>EBP</code></td>
		<td colspan="4"><code>ESP</code></td>
	</tr>
	<tr>
		<td><code>0x010</code></td>
		<td colspan="4"><code>EBX</code></td>
		<td colspan="4"><code>EDX</code></td>
		<td colspan="4"><code>ECX</code></td>
		<td colspan="4"><code>EAX</code></td>
	</tr>
	<tr>
		<td><code>0x020</code></td>
		<td colspan="4"><code>EIP</code></td>
		<td colspan="4"><code>EFLAGS</code></td>
		<td colspan="4"><code>TID</code></td>
		<td><code>O#</code></td>
		<td><code>S#</code></td>
		<td><code>P#</code></td>
		<td><code>PT#</code></td>
	</tr>
	<tr>
		<td><code>0x030</code></td>
		<td colspan="2"><code>FLAGS</code></td>
		<td><code>S#</code></td>
		<td><code>SF</code></td>
		<td colspan="2"><code>MOBJ#</code></td>
		<td colspan="2"><code>SYSC#</code></td>
		<td colspan="4"><code>DESC.TID</code></td>
		<td colspan="4"><code>UPTIME</code></td>
	</tr>
	<tr>
		<td><code>0x040</code></td>
		<td colspan="4"><code>BP0</code></td>
		<td colspan="4"><code>BP1</code></td>
		<td colspan="4"><code>BP2</code></td>
		<td colspan="4"><code>BP3</code></td>
	</tr>
	<tr>
		<td><code>0x050</code></td>
		<td colspan="2"><code>BPF</code></td>
		<td><code>N#</code></td>
		<td><code>S#</code></td>
		<td colspan="4"><code>ALLOC#</code></td>
		<td colspan="4"><code>ALLOCADDR</code></td>
		<td colspan="4"><code>LASTSENT</code></td>
	</tr>
</table>

| Start | End | Description |
| ----- | --- | ----------- |
| `0x060` | `0x07f` | Page directory pointer table |
| `0x080` | `0x0ff` | Process Name (up to 128 bytes) |
| `0x100` | `0x1ff` | Notifications Received |
| `0x200` | `0x3ff` | Owned Containers HNDL Array |
| `0x400` | `0x5ff` | Shared Containers HNDL Array |
| `0x600` | `0x7ff` | Priviledged Share Containers HNDL Array |
| `0x800` | `0xfff` | I/O Bitmap Ports `0x0000` through `0x4000` |

#### Symbols

| Symbol | Meaning |
| ------ | ------- |
| `O#` | Owned Object Count |
| `S#` | Shared Object Count |
| `P#` | Priviledged Shared Object Count |
| `PT#` | Page Table Count |
| `S#` | Last Syscall Number |
| `SF` | Last Syscall Function (AH) |
| `MOBJ#` | Number of Mapped Virtual Pages |
| `SYSC#` | Syscall Count |
| `DESC.TID` | Parent TID/Inherit TID |
| `BP0-3` | Breakpoints 0-3 |
| `BPF` | Breakpoint flags (Same as DR7) |
| `N#` | Notifications Received |
| `S#` | Notifications Sent |
| `ALLOC#` | Memory Count `malloc`'d |
| `ALLOCADDR` | Last Address `malloc`'d |
| `LASTSENT` | Last Notification Sent |

#### Flags

<table>
	<tr>
		<td width="12.5%"></td>
		<td width="12.5%"></td>
		<td width="12.5%"></td>
		<td width="12.5%"></td>
		<td width="12.5%"></td>
		<td width="12.5%"></td>
		<td width="12.5%"></td>
		<td width="12.5%"></td>
	</tr>
	<tr>
		<th>0</th><th>1</th><th>2</th><th>3</th><th>4</th><th>5</th><th>6</th><th>7</th>
	</tr>
	<tr>
		<td>Priviledge</td>
		<td>Status</td>
		<td>Role</td>
		<td>Fatality</td>
		<td>Creation</td>
		<td>Static</td>
		<td>Object Priviledge</td>
		<td>Share</td>
	</tr>
	<tr>
		<td>BP0E</td>
		<td>BP1E</td>
		<td>BP2E</td>
		<td>BP3E</td>
		<td colspan="4">Reserved</td>
	</tr>
</table>

## DDHNDL call structure:

| Register | Description |
| -------- | ----------- |
| `ESI` | Input |
| `EDI` | Output |
| `BH` | Function Number |
| `BL` | Subfunction or data (subsystem dependant) |