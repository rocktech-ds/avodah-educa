import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";
import * as React from "react";

import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
  {
    defaultVariants: {
      size: "default",
      variant: "default",
    },
    variants: {
      size: {
        default: "h-10 px-4 py-2",
        icon: "size-10",
        lg: "h-11 rounded-md px-8",
        sm: "h-9 rounded-md px-3",
      },
      variant: {
        default:
          "bg-platform-500 text-white hover:bg-platform-600 shadow-md hover:shadow-lg",
        destructive:
          "bg-red-500 text-white hover:bg-red-600 shadow-md hover:shadow-lg",
        ghost: "hover:bg-platform-50 hover:text-platform-700 dark:hover:bg-platform-900/20 dark:hover:text-platform-300",
        link: "text-platform-600 underline-offset-4 hover:underline dark:text-platform-400",
        outline:
          "border border-platform-300 bg-white hover:bg-platform-50 hover:text-platform-700 dark:border-platform-600 dark:bg-transparent dark:hover:bg-platform-900/20 dark:hover:text-platform-300",
        secondary:
          "bg-gray-100 text-gray-900 hover:bg-gray-200 shadow-sm hover:shadow-md",
        success:
          "bg-emerald-500 text-white hover:bg-emerald-600 shadow-md hover:shadow-lg",
        warning:
          "bg-amber-500 text-white hover:bg-amber-600 shadow-md hover:shadow-lg",
      },
    },
  }
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
  VariantProps<typeof buttonVariants> {
  asChild?: boolean
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ asChild = false, className, size, variant, ...props }, ref) => {
    const Comp = asChild ? Slot : "button";
    return (
      <Comp
        className={cn(buttonVariants({ className, size, variant }))}
        ref={ref}
        {...props}
      />
    );
  }
);
Button.displayName = "Button";

export { Button, buttonVariants };