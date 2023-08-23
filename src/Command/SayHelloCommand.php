<?php

namespace YourNamespace\App\Command;

use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

/**
 * Say hello command.
 *
 * Allows to say hello.
 *
 * @package YourNamespace\App\Command
 */
class SayHelloCommand extends Command {

  /**
   * {@inheritdoc}
   */
  protected static $defaultName = 'app:say-hello';

  /**
   * {@inheritdoc}
   */
  protected function configure(): void {
    $this
      ->setDescription('Says hello')
      ->setHelp('This command allows you to say hello...');
  }

  /**
   * {@inheritdoc}
   */
  protected function execute(InputInterface $input, OutputInterface $output): int {
    $output->writeln('Hello, Symfony console!');

    return Command::SUCCESS;
  }

}
