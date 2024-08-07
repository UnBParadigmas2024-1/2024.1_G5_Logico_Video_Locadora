:- dynamic cliente/5. %está aqui para possibilar alteracao nos fatos do cliente
:- dynamic filme/7. %está aqui para possibilar alteracao nos fatos do filme
:- dynamic historico_aluguel/3.
% Limpar histórico de aluguéis ao iniciar o programa
:- retractall(historico_aluguel(_,_)).
:- consult('filme.pl').
:- consult('cliente.pl').




%Processo de recomendação de filme


% Função para listar todos os clientes com seus códigos e nomes, vai ser utilizada no processo de recomendação de filme -> o operador do sistema vai escolher qual cliente deseja e filmes recomendados vão aparecer para ele
lista_de_clientes :-
    writeln('Clientes Cadastrados: '),
    cliente(Codigo, Nome, _, _, _),  
    format('~w: ~w~n', [Codigo, Nome]),
    fail.
    lista_de_clientes.

% Função para listar todos os filmes. Ainda verificando se vamos adicionar todos os filmes da base de dados
lista_de_filmes :-
    findall((Codigo, Titulo), filme(Codigo, Titulo, _, _, _, _, true), Filmes),
    writeln('Filmes disponíveis:'),
    listarAuxFilmes(Filmes).


% auxliar para listar os clientes cadastrados no formato esperado
listar([]).
listar([(Codigo, Titulo) | Resto]) :-
    format('Código: ~w - ~w~n', [Codigo, Titulo]),
    listar(Resto).

% auxiliar para listar todos os filmes cadastrados no formato esperado. Precisa ser diferente do filme porque conta com argumentos difrentes
listarAuxFilmes([]).
listarAuxFilmes([(Codigo, Nome)|T]) :-
    format('Código: ~w, Nome: ~w~n', [Codigo, Nome]),
    listarAuxFilmes(T).

% recomendador de filmes para ser utilizado dentro da rotina do menu
recomendar_filmes(GeneroFavorito, FilmesRecomendados) :-
    findall((Codigo, Titulo),
            (filme(Codigo, Titulo, _, _, Generos, _, true),
        
             member(GeneroFavorito, Generos)),
            FilmesRecomendados).


% Recomendador pra ser chamado no menu. 

menu_recomendacao :-
    lista_de_clientes,
    writeln('Escolha um cliente pelo código:'),


    read_line_to_string(user_input, Input),
    atom_number(Input, Codigo),
    %read(Codigo),
    (   cliente(Codigo, Nome, _, GeneroFavorito, _) ->
        writeln('Cliente encontrado, gerando recomendações...'), % Depuração
        recomendar_filmes(GeneroFavorito, FilmesRecomendados),
        (   FilmesRecomendados \= [] ->
            format('Recomendações para ~w:~n', [Nome]),
            listar(FilmesRecomendados)
        ;   writeln('Sem recomendações.')
        )
    ;   writeln('Cliente não encontrado.'), menu_recomendacao
    ).

% Processo de locação de filme
% precisa mostrar o codigo dos filmes, somar o valor dos filmes, descontar da carteira do cliente, se tiver fundos? beleza. Se não tiver, reportar que o saldo é insuficiente e voltar ao menu


% Função para escolha de filmes. Vai ser chamada dentro do processo de locação
escolher_filmes(FilmesEscolhidos) :-
    listar_filmes,
    writeln('Escolha filmes pelo código (digite "fim" para terminar):'),
    escolher_filmes_aux(FilmesEscolhidos).


% Funcao para realizar a seleçaõ dos filmes.Os filmes escolhidos aqui 
escolher_filmes_aux(FilmesEscolhidos) :-
    read_line_to_string(user_input, Input),
    (   Input == "fim" 
    ->  FilmesEscolhidos = []
    ;   (   atom_number(Input, Codigo),
            filme(Codigo, _, _, _, _, _, true)
        ->  FilmesEscolhidos = [Codigo | Outros],
            escolher_filmes_aux(Outros)
        ;   writeln('Filme não encontrado ou indisponível.'),
            escolher_filmes_aux(FilmesEscolhidos)
        )
    ).


% Funcao para escolher cliente que irá realizar locacao
escolher_cliente(Codigo) :-
    lista_de_clientes,
    writeln('Escolha um cliente pelo código:'),
    read_line_to_string(user_input, Input),
    atom_number(Input, Codigo),
    (   cliente(Codigo, _, _, _, _)
    ->  true
    ;   writeln('Cliente não encontrado.'),
        escolher_cliente(Codigo)).

% Funcao para calcular o valor total dos filmes
calcular_valor_filmes([], 0).
calcular_valor_filmes([Codigo|T], Total) :-
    filme(Codigo, _, _, _, _, Valor, _),
    calcular_valor_filmes(T, Subtotal),
    Total is Valor + Subtotal.

% Menu principal para realizar a locação de filmes
menu_realizar_locacao :-
    escolher_cliente(CodigoCliente),
    escolher_filmes(FilmesEscolhidos),
    calcular_valor_filmes(FilmesEscolhidos, ValorTotal),
    cliente(CodigoCliente, Nome, _, _, Saldo),
    (   Saldo >= ValorTotal
    ->  format('Pronto!!! Locação foi realizada para o cliente: ~w.~n', [Nome]),
        atualizar_saldo(CodigoCliente, ValorTotal),
        registrar_aluguel(CodigoCliente, FilmesEscolhidos), % Registro de histórico de aluguel
        atualizar_status_filmes(FilmesEscolhidos)
    ;   format('Cliente com saldo insuficiente. A locação não foi realizada para o cliente: ~w.~n', [Nome]),
        writeln('Voltando ao menu principal.')
    ).

% Funcao para atualizar o saldo disponivel do cliente
atualizar_saldo(CodigoCliente, ValorTotal) :-
    cliente(CodigoCliente, Nome, CPF, GeneroFavorito, Saldo),
    NovoSaldo is Saldo - ValorTotal,
    retract(cliente(CodigoCliente, Nome, CPF, GeneroFavorito, Saldo)),
    assertz(cliente(CodigoCliente, Nome, CPF, GeneroFavorito, NovoSaldo)).

% Funcao para atualizar status dos filmes
atualizar_status_filmes([]).
atualizar_status_filmes([Codigo|T]) :-
    filme(Codigo, Titulo, Ano, Nota, Generos, Valor, _),
    retract(filme(Codigo, Titulo, Ano, Nota, Generos, Valor, true)),
    assertz(filme(Codigo, Titulo, Ano, Nota, Generos, Valor, false)),
    atualizar_status_filmes(T).

% Funcao para atualizar status dos filmes na devolucao
atualizar_status_filmes_d(Codigo) :-
    filme(Codigo, Titulo, Ano, Nota, Generos, Valor, _),
    retract(filme(Codigo, Titulo, Ano, Nota, Generos, Valor, false)),
    assertz(filme(Codigo, Titulo, Ano, Nota, Generos, Valor, true)).

% Função para registrar o histórico de aluguel
registrar_aluguel(_, []).
registrar_aluguel(CodigoCliente, [FilmeCodigo | Outros]) :-
    assertz(historico_aluguel(FilmeCodigo, CodigoCliente)),
    registrar_aluguel(CodigoCliente, Outros).

% Função para listar todos os aluguéis registrados
listar_alugueis :-
    writeln('--- Lista de Aluguéis Registrados ---'),
    historico_aluguel(FilmeCodigo, CodigoCliente),
    filme(FilmeCodigo, Titulo, _, _, _, _, _),
    cliente(CodigoCliente, Nome, _, _, _),
    format('Cliente: ~w - Filme: ~w~n', [Nome, Titulo]),
    fail.
listar_alugueis.

% Função para permitir que um cliente devolva um filme
devolver_filme :-
    writeln('--- Devolução de Filme ---'),
    escolher_cliente(CodigoCliente),
    listar_alugueis_cliente(CodigoCliente),
    writeln('Digite o código do filme que deseja devolver (digite "fim" para cancelar):'),
    read_line_to_string(user_input, Input),
    (   Input == "fim" -> writeln('Devolução cancelada.')
    ;   atom_number(Input, FilmeCodigo),
        historico_aluguel(FilmeCodigo, CodigoCliente),
        retract(historico_aluguel(FilmeCodigo, CodigoCliente)),
        atualizar_status_filmes_d(FilmeCodigo),
        filme(FilmeCodigo, Titulo, _, _, _, _, _),
        format('Filme ~w devolvido pelo cliente.~n', [Titulo])
    ;   writeln('Cliente não possui esse filme alugado.'),
        devolver_filme
    ).

% Função auxiliar para listar aluguéis de um cliente específico
listar_alugueis_cliente(CodigoCliente) :-
    writeln('--- Aluguéis do Cliente ---'),
    historico_aluguel(FilmeCodigo, CodigoCliente),
    filme(FilmeCodigo, Titulo, _, _, _, _, _),
    format('Código do Filme: ~w, Título: ~w~n', [FilmeCodigo, Titulo]),
    fail.
listar_alugueis_cliente(_).


% Chamada para limpar o histórico de aluguéis ao iniciar
:- retractall(historico_aluguel(_, _)).