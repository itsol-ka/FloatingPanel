// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit

class ModalTransition: NSObject, UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ModalPresentTransition()
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ModalDismissTransition()
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PresentationController(presentedViewController: presented, presenting: presenting)
    }
}

class PresentationController: UIPresentationController {
    override func presentationTransitionWillBegin() {
        // Must call here even if duplicating on in containerViewWillLayoutSubviews()
        // Because it let the floating panel present correctly with the presentation animation
        addFloatingPanel()
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        // For non-animated presentation
        if let fpc = presentedViewController as? FloatingPanelController, fpc.state == .hidden {
            fpc.show(animated: false, completion: nil)
        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if let fpc = presentedViewController as? FloatingPanelController {
            // For non-animated dismissal
            if fpc.state != .hidden {
                fpc.hide(animated: false, completion: nil)
            }
            fpc.view.removeFromSuperview()
        }
    }

    override func containerViewWillLayoutSubviews() {
        guard
            let fpc = presentedViewController as? FloatingPanelController
            else { fatalError() }

        /*
         * Layout the views managed by `FloatingPanelController` here for the
         * sake of the presentation and dismissal modally from the controller.
         */
        addFloatingPanel()

        // Forward touch events to the presenting view controller
        (fpc.view as? PassThroughView)?.eventForwardingView = presentingViewController.view
    }

    @objc func handleBackdrop(tapGesture: UITapGestureRecognizer) {
        presentedViewController.dismiss(animated: true, completion: nil)
    }

    private func addFloatingPanel() {
        guard
            let containerView = self.containerView,
            let fpc = presentedViewController as? FloatingPanelController
            else { fatalError() }

        containerView.addSubview(fpc.view)
        fpc.view.frame = containerView.bounds
        fpc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
}

class ModalPresentTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        guard
            let fpc = transitionContext?.viewController(forKey: .to) as? FloatingPanelController
        else { fatalError()}

        let animator = fpc.delegate?.floatingPanel?(fpc, animatorForPresentingTo: fpc.layout.initialState)
            ?? FloatingPanelDefaultBehavior().addPanelAnimator(fpc, to: fpc.layout.initialState)
        return TimeInterval(animator.duration)
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fpc = transitionContext.viewController(forKey: .to) as? FloatingPanelController
        else { fatalError() }

        fpc.show(animated: true) {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

class ModalDismissTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        guard
            let fpc = transitionContext?.viewController(forKey: .from) as? FloatingPanelController
        else { fatalError()}

        let animator = fpc.delegate?.floatingPanel?(fpc, animatorForDismissingWith: .zero)
            ?? FloatingPanelDefaultBehavior().removePanelAnimator(fpc, from: fpc.state, with: .zero)
        return TimeInterval(animator.duration)
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fpc = transitionContext.viewController(forKey: .from) as? FloatingPanelController
        else { fatalError() }

        fpc.hide(animated: true) {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
