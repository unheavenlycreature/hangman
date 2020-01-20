# frozen_string_literal: true

require 'JSON'

# Class that controls a game of hangman.
class Hangman
  def initialize
    puts 'Welcome to Hangman! Are you restarting a saved game? (y/n)'
    saved_game = gets.chomp.downcase == 'y'
    init_new_game unless saved_game
    init_from_save if saved_game
  end

  def play
    until @remaining_mistakes.zero?
      display_current_progress
      letter = get_letter_or_save_and_exit
      check_word_for_letter(letter)
      unless @guess.include? '_'
        puts "Congrats, you guessed the correct word, #{@word.join('')}!"
        return
      end
    end
    puts "Sorry, you lose! The word was #{@word.join('')}."
  end

  private

  def init_new_game
    puts "Okay, we'll start a new game!"
    @word = choose_word.downcase.split('')
    @guess = Array.new(@word.length, '_')
    @incorrect_guesses = []
    @remaining_mistakes = 6
    @file_name = "hangman_#{Time.now.to_i}.json"
  end

  def init_from_save
    file_name = get_save_file_name
    file = File.open(file_name, 'r')
    game_state = JSON.parse(file.read, symbolize_names: true)
    @word = game_state[:word]
    @guess = game_state[:guess]
    @incorrect_guesses = game_state[:incorrect_guesses]
    @remaining_mistakes = game_state[:remaining_mistakes]
    @file_name = file_name
    file.close
  end

  def get_save_file_name
    puts 'What is the name of your save file?'
    file_name = gets.chomp
    until File.exist?(file_name)
      puts "Sorry, I can't find that file. What's the file name?"
      file_name = gets.chomp
    end
    file_name
  end

  def check_word_for_letter(guessed_letter)
    word_contains_letter = false
    @word.each_with_index do |letter, index|
      if letter == guessed_letter
        word_contains_letter = true
        @guess[index] = letter
      end
    end

    return if word_contains_letter

    @remaining_mistakes -= 1
    @incorrect_guesses << guessed_letter
  end

  def display_current_progress
    puts "You can make #{@remaining_mistakes} more mistakes until losing."
    puts "Word so far: #{@guess.join(' ')}"
    puts "Incorrect guesses: #{@incorrect_guesses.join(', ')}"
  end

  def get_letter_or_save_and_exit
    print 'Save the game by typing "save", or enter a letter: '
    input = gets.chomp.downcase
    until valid_guess_or_save input
      puts "You can only input a single letter at a time, that hasn't been \
        guessed before, or \"save\" the game"
      input = gets.chomp.downcase
    end
    save_and_exit if input == 'save'
    input
  end

  def valid_guess_or_save(input)
    input.downcase == 'save' || (input.length == 1 && \
      !@guess.include?(input) && !@incorrect_guesses.include?(input))
  end

  def choose_word
    eligible_words = File.readlines('dictionary.txt').filter do |word|
      word.gsub!(/[\r\n]/, '')
      word.length > 4 && word.length < 13
    end
    eligible_words[rand(eligible_words.length)]
  end

  def save_and_exit
    game_file = File.open(@file_name, 'w')
    JSON.dump({
                word: @word,
                guess: @guess,
                incorrect_guesses: @incorrect_guesses,
                remaining_mistakes: @remaining_mistakes
              }, game_file)
    game_file.close
    puts "Game saved to file: #{@file_name}. Goodbye!"
    exit
  end
end

Hangman.new.play
