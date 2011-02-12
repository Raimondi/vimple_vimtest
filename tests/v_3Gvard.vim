" Test ar in visual from the top on sample 1
call vimtest#StartTap()
call vimtap#Plan(3)
edit v_2Gvard.in
set filetype=ruby
source ~/Documents/Source/rubytxtobj/ftplugin/ruby/rubytextobjects.vim
call vimtap#Ok(hasmapto('<Plug>RubyTextObjectsAll'), '<Plug> mappings exist.')
call vimtap#Ok(mapcheck('ar', 'v') != '', 'ar mapping exists.')
2
normal vard
call vimtap#Is(getline(1,4), ['# Sample 1', ''], 'Delete')
call vimtest#Quit()

