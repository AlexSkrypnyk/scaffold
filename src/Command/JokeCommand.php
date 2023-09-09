<?php

namespace YourNamespace\App\Command;

use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;

/**
 * Joke command.
 *
 * Allows to get a random joke.
 *
 * @package YourNamespace\App\Command
 */
class JokeCommand extends Command {

  const JOKE_API_ENDPOINT = 'https://official-joke-api.appspot.com/jokes/%s/random';

  /**
   * {@inheritdoc}
   */
  protected static $defaultName = 'app:joke';

  /**
   * {@inheritdoc}
   */
  protected function configure(): void {
    $this
      ->addOption(
        name: 'topic',
        mode: InputOption::VALUE_OPTIONAL,
        default: 'general'
      );
  }

  /**
   * {@inheritdoc}
   */
  protected function execute(InputInterface $input, OutputInterface $output): int {
    $topic = $input->getOption('topic');
    $topic = is_string($topic) ? $topic : 'general';

    $response = file_get_contents(sprintf(self::JOKE_API_ENDPOINT, $topic));

    if (empty($response)) {
      $output->writeln('<error>Unable to retrieve a joke payload.</error>');

      return Command::FAILURE;
    }

    $json = json_decode($response);

    if (empty($json)) {
      $output->writeln('<error>Unable to retrieve a joke payload.</error>');

      return Command::FAILURE;
    }

    /** @var \stdClass $joke */
    [$joke] = (array) $json;

    $output->writeln($joke->setup);
    $output->writeln("<info>{$joke->punchline}</info>\n");

    return Command::SUCCESS;
  }

}
