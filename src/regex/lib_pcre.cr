@[Link("pcre")]
lib LibPCRE
  type Pcre = Void*
  type PcreExtra = Void*
  fun compile = pcre_compile(pattern : UInt8*, options : Int32, errptr : UInt8**, erroffset : Int32*, tableptr : Void*) : Pcre
  fun study = pcre_study(code : Pcre, options : Int32, errptr : UInt8**) : PcreExtra
  fun exec = pcre_exec(code : Pcre, extra : PcreExtra, subject : UInt8*, length : Int32, offset : Int32, options : Int32,
                ovector : Int32*, ovecsize : Int32) : Int32
  fun full_info = pcre_fullinfo(code : Pcre, extra : PcreExtra, what : Int32, where : Int32*) : Int32
  fun get_stringnumber = pcre_get_stringnumber(code : Pcre, string_name : UInt8*) : Int32

  INFO_CAPTURECOUNT  = 2
  INFO_NAMEENTRYSIZE = 7
  INFO_NAMECOUNT     = 8
  INFO_NAMETABLE     = 9

  $pcre_malloc : (UInt32 -> Void*)
  $pcre_free : (Void* ->)
end

LibPCRE.pcre_malloc = ->GC.malloc(UInt32)
LibPCRE.pcre_free = ->GC.free(Void*)
