local labels={
 language={'Idioma / Language','Language / Idioma'},quick_nurse={'Enfermeira sem conversa','Nurse: no dialogue'},experience={'Divisão de experiência','Experience distribution'},
 reusable_tms={'TMs reutilizáveis','Reusable TMs'},hm_without_move={'HMs sem aprender o golpe','HMs without learning the move'},disable_help={'Desativar ajuda L/R','Disable L/R help'},
 heal_caught={'Curar após captura','Heal caught Pokémon'},always_catch={'Captura garantida','Guaranteed catch'},exp_multiplier={'Multiplicador de XP','XP multiplier'},money_multiplier={'Multiplicador de dinheiro','Money multiplier'},
 infinite_held={'Itens equipados reutilizáveis','Reusable held consumables'},instant_eggs={'Ovos: eclosão no próximo passo','Eggs: hatch on next step'},auto_flash={'Flash automático','Automatic Flash'},instant_text={'Textos instantâneos','Instant text'},
}
return function(language)
 local en=language=='en';local col=en and 2 or 1
 local rows={{key='language',label=labels.language[col],type='choice',default='pt-BR',choices={{'English','en'},{'Português','pt-BR'}}}}
 local keys={'quick_nurse','experience','reusable_tms','hm_without_move','disable_help','heal_caught','always_catch','exp_multiplier','money_multiplier','infinite_held','instant_eggs','auto_flash','instant_text'}
 for _,key in ipairs(keys)do
  local row={key=key,label=labels[key][col],type='toggle',default=key=='quick_nurse'}
  if key=='experience'then row.type='choice';row.default='native';row.choices={{en and 'Individual / native' or 'Individual / nativa','native'},{en and 'Party: 50% + 50%'or 'Grupo: 50% + 50%','party'}}
  elseif key=='exp_multiplier'or key=='money_multiplier'then row.type='choice';row.default=1;row.choices={{en and 'Off (1x)'or 'Desligado (1x)',1},{'2x',2},{'3x',3},{'5x',5},{'10x',10}}end
  rows[#rows+1]=row
 end
 return rows
end
