ENTRY(_start)
OUTPUT_FORMAT(binary)

SECTIONS
{
  output :
    {
      stage1.elf(.text)
      stage2.elf(.text)
    }
}