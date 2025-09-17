import { cva, type VariantProps } from "class-variance-authority";
import * as React from "react";

import { cn } from "@/lib/utils";

const badgeVariants = cva(
  "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
  {
    defaultVariants: {
      variant: "default",
    },
    variants: {
      variant: {
        default:
          "border-transparent bg-avodah-500 text-white hover:bg-avodah-600 shadow-sm",
        destructive:
          "border-transparent bg-red-500 text-white hover:bg-red-600 shadow-sm",
        info:
          "border-transparent bg-study-100 text-study-800 hover:bg-study-200 dark:bg-study-900/20 dark:text-study-300 dark:hover:bg-study-900/30",
        outline: 
          "border-avodah-300 text-avodah-700 hover:bg-avodah-50 dark:border-avodah-600 dark:text-avodah-300 dark:hover:bg-avodah-900/20",
        secondary:
          "border-transparent bg-study-500 text-white hover:bg-study-600 shadow-sm",
        success:
          "border-transparent bg-emerald-100 text-emerald-800 hover:bg-emerald-200 dark:bg-emerald-900/20 dark:text-emerald-300 dark:hover:bg-emerald-900/30",
        warning:
          "border-transparent bg-wisdom-100 text-wisdom-800 hover:bg-wisdom-200 dark:bg-wisdom-900/20 dark:text-wisdom-300 dark:hover:bg-wisdom-900/30",
        focus:
          "border-transparent bg-focus-100 text-focus-800 hover:bg-focus-200 dark:bg-focus-900/20 dark:text-focus-300 dark:hover:bg-focus-900/30",
      },
    },
  }
);

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
  VariantProps<typeof badgeVariants> {}

function Badge({ className, variant, ...props }: BadgeProps) {
  return (
    <div className={cn(badgeVariants({ variant }), className)} {...props} />
  );
}

export { Badge, badgeVariants };