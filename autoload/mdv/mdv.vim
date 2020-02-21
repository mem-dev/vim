function! s:api_req(url, params, method)
    let base_url = 'http://localhost:3000/api/v2'
    let url = base_url . a:url
    let token = 0
    let g:mdv_token = get(g:, 'mdv_token', "")
    let header = {"Authorization": g:mdv_token}
    if a:method == 'get'
        let response =  webapi#http#get(url, a:params, header)
    elseif a:method == 'post'
        let response =  webapi#http#post(url, a:params, header)
    endif
    return response
endfunction

function! s:get_visual_selection()
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
        return ''
    endif
    let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
    return join(lines, "\n")
endfunction

function! InitMDV()
    let selectedtext = s:get_visual_selection()
    let about = input('What did you learn? ')
    let auth = s:check_auth()
    if auth == 0
        return 0
    endif
    call s:post_snippet(about, selectedtext)
    echo "Snippet has been created successfully!"
endfunction

function! s:authorize(token)
    let response =  s:api_req('/authorize/ext_auth', {"id": a:token}, 'post')
    if response.status == 200
        let response_content = webapi#json#decode(response.content)
	let g:mdv_token = response_content.token
	return 1
    endif
    redraw
    echo "Invalid Auth Token!"
    return 0
endfunction

function! s:post_snippet(about, content)
    let payload = {
    \ "content": a:content, 
    \ "title": a:about, 
    \ "topic": '', 
    \ "source": '', 
    \ "syntax": ''
    \}
    echo webapi#http#decodeURI(webapi#json#encode(payload))
    let response = s:api_req('/snippets', payload, "post")
    echo response
    if response.status == 200
	redraw
        echo "Snippet has been created successfully!"
	return 1
    endif	
endfunction

function! s:check_auth()
    let g:mdv_token = get(g:, 'mdv_token', "")
    if g:mdv_token == ""
	let token = input("Enter your token: ")
        let auth = s:authorize(token)
        if auth == 0
            return 0
        endif
    endif
    return 1
endfunction

function! InitMDVCmd()
    let lastindex = histnr('cmd')
    let lastcommand = histget('cmd', lastindex - 1)
    let about = input('What did the last :ex do? ')
    let auth = s:check_auth()
    if auth == 0
        return 0
    endif
    call s:post_snippet(about, lastcommand)
endfunction

vnoremap <leader>mdv :<c-u>call InitMDV()<cr>
command! Mdv call InitMDVCmd()
