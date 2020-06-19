ENTRY(_start)

SECTIONS
{
  output :
    {
      stage1.elf(.text)
      stage2.elf(.text)
    }
}