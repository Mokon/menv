#include <string>
#include <stdio.h>
#include <stdlib.h>

#include <sys/wait.h>

inline int
exit_with_message(const char* message,
                  int return_code = EXIT_FAILURE) {
  printf("%s\n", message);
  return return_code;
}

int
main(int argc, char **argv) {
  if (argc <= 1) {
    return exit_with_message("please provide wait_status");
  } else if (argc > 2) {
    return exit_with_message("please only provide wait_status");
  }

  int wait_status{0};
  try {
     wait_status = std::stoi(argv[1]);
  } catch (const std::exception&) {
    return exit_with_message("wait_status parse error");
  }

  printf("raw wait status = %d\n", wait_status);

  if (WIFEXITED(wait_status)) {
    printf("\tprocess terminated normally, "
           "called exit(3), _exit(2), or returned fromm main().\n");

    int exit_status = WEXITSTATUS(wait_status);
    printf("\texit status = %d\n", exit_status);
    if (exit_status > 128) {
        printf("\texited with signal = %d\n", exit_status-128);
    }
  }

  if (WIFSIGNALED(wait_status)) {
    printf("\tprocess terminated by a signal\n");
    printf("\texited with signal = %d\n", WTERMSIG(wait_status));

    if (WCOREDUMP(wait_status)) {
        printf("\tprocess terminated by a core dump\n");
    }
  }

  if (WIFSTOPPED(wait_status)) {
    printf("process was stopped by delivery of a signal\n");
    printf("\tstopped with signal = %d\n", WSTOPSIG(wait_status));
  }

  if (WIFCONTINUED(wait_status)) {
    printf("\tprocess was resumed by delivery  of  SIG‐CONT\n");
  }

  return EXIT_SUCCESS;
}
