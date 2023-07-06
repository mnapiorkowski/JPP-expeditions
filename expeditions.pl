% Michał Napiórkowski

:- ensure_loaded(library(lists)).

track_id((Id, _, _, _, _), Id).
track_start((_, Start, _, _, _), Start).
track_finish((_, _, Finish, _, _), Finish).
track_type((_, _, _, Type, _), Type).
track_length((_, _, _, _, Length), Length).


convert_length_cond(eq, L, ('=:=', L)).
convert_length_cond(lt, L, ('<', L)).
convert_length_cond(le, L, ('=<', L)).
convert_length_cond(gt, L, ('>', L)).
convert_length_cond(ge, L, ('>=', L)).


process_cond(rodzaj(T), Types, [T | Types], _) :-
    atomic(T).

process_cond(dlugosc(Op, L), Types, Types, LengthCond) :-
    integer(L), % czy L jest liczbą całkowitą
    L >= 0,
    convert_length_cond(Op, L, Cond), % czy Op jest poprawnym warunkiem
    !, % aby nie dopasowywać do kolejnego predykatu, gdy błąd już wystąpił
    (var(LengthCond) -> 
        LengthCond = Cond % warunek na długość pojawia się po raz pierwszy
    ;   
        write('Error: za duzo warunkow na dlugosc.'), nl,
        fail
    ).

process_cond(Cond, _, _, _) :-
    format('Error: niepoprawny warunek - ~w.~n', [Cond]),
    fail.


process_conditions((Cond, Rest), Types, TAcc, LengthCond) :-
    !, % aby nie dopasowywać do kolejnego predykatu, gdy błąd już wystąpił
    process_cond(Cond, TAcc, NewTAcc, LengthCond),
    !, % aby nie sprawdzać ponownie wcześniejszych warunków
    process_conditions(Rest, Types, NewTAcc, LengthCond).

process_conditions(Cond, Types, TAcc, LengthCond) :- 
    process_cond(Cond, TAcc, Types, LengthCond). % ostatni warunek

process_conditions(nil, Types, _) :-
    Types = []. % brak warunków - lista typów jest pusta

process_conditions(Conditions, Types, LengthCond) :-
    process_conditions(Conditions, Types, [], LengthCond).


% gdy lista typów jest pusta, wszystkie trasy są brane pod uwagę
filter_tracks(Tracks, Tracks, []).

filter_tracks([], [], _).

% trasa jest jednego z zadanych typów, więc zostaje
filter_tracks([Track | Rest], [Track | AccRest], Types) :-
    track_type(Track, Type),
    member(Type, Types),
    filter_tracks(Rest, AccRest, Types).

filter_tracks([_ | Rest], TracksAcc, Types) :-
    filter_tracks(Rest, TracksAcc, Types).


track_to(_, [], _) :- fail. % nie znaleziono trasy o zadanym końcu

track_to(Track, [Track | _], Finish) :-
    track_finish(Track, Finish). % trasa kończy się w zadanym miejscu

track_to(Track, [_ | Rest], Finish) :-
    track_to(Track, Rest, Finish). % sprawdzamy kolejną trasę


print_expedition([]).

print_expedition([Track | Rest]) :-
    track_id(Track, Id),
    track_type(Track, Type),
    track_finish(Track, Finish),
    format(' -(~w,~w)-> ~w', [Id, Type, Finish]),
    print_expedition(Rest).

print_expedition([Track | Rest], Length) :-
    track_start(Track, Start),
    nl, write(Start),
    print_expedition([Track | Rest]),
    format('~nDlugosc trasy: ~d.~n', [Length]).


check_length_cond(Length, (Op, Val)) :-
    Cond =.. [Op, Length, Val],
    call(Cond). % prawda jeśli Op(Length, Val)
    

% miejsce początku i końca wyprawy jest takie samo
expeditions(Expedition, Length, _, Start, Start, LengthCond) :-
    (Length > 0 -> 
        (var(LengthCond) -> 
            print_expedition(Expedition, Length) % brak warunku na długość
        ;   
            check_length_cond(Length, LengthCond) -> 
                print_expedition(Expedition, Length) % warunek spełniony
        )
    ),
    fail. % aby szukać kolejnych wypraw

expeditions(Expedition, Length, Tracks, Start, Finish, LengthCond) :-
    track_to(Track, Tracks, Finish), % znajdź trasę o końcu w Finish
    track_start(Track, NewFinish), % jej początek będzie nast. końcem
    track_length(Track, L),
    NewLength is Length + L,
    select(Track, Tracks, NewTracks), % usuń tę trasę z listy dostępnych
    expeditions( % rekurencyjnie szukaj wyprawy do NewFinish
        [Track | Expedition], NewLength, NewTracks, 
        Start, NewFinish, LengthCond
    ).

expeditions(Tracks, nil, nil, LengthCond) :- % dowolny początek i koniec
    expeditions([], 0, Tracks, _, _, LengthCond); 
    true. % 'or true' - aby wyszukiwanie skończyło się sukcesem

expeditions(Tracks, Start, nil, LengthCond) :- % tylko początek podany
    expeditions([], 0, Tracks, Start, _, LengthCond); 
    true.

expeditions(Tracks, nil, Finish, LengthCond) :- % tylko koniec podany
    expeditions([], 0, Tracks, _, Finish, LengthCond);
    true.

expeditions(Tracks, Start, Finish, LengthCond) :- % początek i koniec podane
    expeditions([], 0, Tracks, Start, Finish, LengthCond);
    true.


read_conditions(Types, LengthCond) :-
    write('Podaj warunki : '),
    read(Conditions),
    (process_conditions(Conditions, Types, LengthCond) ->
        true
    ;   
        read_conditions(Types, LengthCond) % gdy niepoprawne warunki
    ).


read_start(Start) :-
    write('Podaj miejsce startu:  '),
    read(Input),
    (atomic(Input) -> 
        Start = Input
    ;   
        write('Error: niepoprawne miejsce startu.'), nl,
        read_start(Start)
    ).


read_finish(Finish) :-
    write('Podaj miejsce koncowe: '),
    read(Input),
    (atomic(Input) ->
        Finish = Input
    ;   
        write('Error: niepoprawne miejsce koncowe.'), nl,
        read_finish(Finish)
    ).


new_query(AllTracks) :-
    read_start(Start),
    (Start = koniec -> 
        write('Koniec programu. Milych wedrowek!'), nl
    ;   
        read_finish(Finish),
        (Finish = koniec ->  
            write('Koniec programu. Milych wedrowek!'), nl
        ;   
            read_conditions(Types, LengthCond),
            filter_tracks(AllTracks, Tracks, Types), % zost. te o danych typach
            expeditions(Tracks, Start, Finish, LengthCond), % znajdź i wypisz
            nl, new_query(AllTracks)
        )
    ).


insert_track( % trasa jednokierunkowa
    trasa(Id, Start, Finish, Type, jeden, Length),
    [(Id, Start, Finish, Type, Length) | Rest],
    Rest).

insert_track( % trasa dwukierunkowa jako dwie jednokierunkowe
    trasa(Id, Start, Finish, Type, oba, Length),
    [(Id, Start, Finish, Type, Length),
     (Id, Finish, Start, Type, Length) | Rest],
    Rest).


read_tracks(Tracks) :- 
    read(Term),
    (Term = end_of_file ->  
        Tracks = []
    ;   
        insert_track(Term, Tracks, Rest),  
        read_tracks(Rest)
    ).

read_tracks(File, Tracks) :-
    see(File),
    read_tracks(Tracks),
    seen.


user:runtime_entry(start) :- 
    (current_prolog_flag(argv, [File]) ->
        set_prolog_flag(fileerrors, off),
        prompt(_, ''), 
        (read_tracks(File, Tracks) ->
            new_query(Tracks)
        ;   
            format('Error: nie mozna odczytac pliku ~w.', [File]), nl
        )
    ;
	    write('Error: zla liczba argumentow.'), nl
    ).
